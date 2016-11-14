package main_test

import (
	"bytes"
	"io"
	"io/ioutil"
	"net/http"
	"os/exec"
	"time"

	"mime/multipart"

	"strings"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gexec"
)

var _ = Describe("Signing URLs", func() {

	var session *gexec.Session

	BeforeSuite(func() {
		pathToWebserver, err := gexec.Build("github.com/petergtz/bitsgo")
		Ω(err).ShouldNot(HaveOccurred())

		session, err = gexec.Start(exec.Command(pathToWebserver), GinkgoWriter, GinkgoWriter)
		Ω(err).ShouldNot(HaveOccurred())
		time.Sleep(200 * time.Millisecond)
		Expect(session.ExitCode()).To(Equal(-1), "Webserver error message: %s", string(session.Err.Contents()))
	})

	AfterSuite(func() {
		if session != nil {
			session.Kill()
		}
		gexec.CleanupBuildArtifacts()
	})

	It("return http.StatusNotFound for a package that does not exist", func() {
		Expect(http.Get("http://internal.127.0.0.1.xip.io:8000/packages/notexistent")).
			To(WithTransform(GetStatusCode, Equal(http.StatusNotFound)))
	})

	It("return http.StatusOK for a package that does exist", func() {
		request := NewPutRequest("http://internal.127.0.0.1.xip.io:8000/packages/myguid", map[string]map[string]io.Reader{
			"package": map[string]io.Reader{"somefilename": strings.NewReader("My test string")},
		})

		Expect(http.DefaultClient.Do(request)).To(WithTransform(GetStatusCode, Equal(201)))

		Expect(http.Get("http://internal.127.0.0.1.xip.io:8000/packages/myguid")).
			To(WithTransform(GetStatusCode, Equal(http.StatusOK)))
	})

	It("returns http.StatusForbidden when accessing package through public host without md5", func() {
		Expect(http.Get("http://public.127.0.0.1.xip.io:8000/packages/notexistent")).
			To(WithTransform(GetStatusCode, Equal(http.StatusForbidden)))
	})

	It("returns http.StatusOK when accessing package through public host with md5", func() {
		request := NewPutRequest("http://internal.127.0.0.1.xip.io:8000/packages/myguid", map[string]map[string]io.Reader{
			"package": map[string]io.Reader{"somefilename": strings.NewReader("lalala\n\n")},
		})
		Expect(http.DefaultClient.Do(request)).To(WithTransform(GetStatusCode, Equal(201)))

		response, e := http.Get("http://internal.127.0.0.1.xip.io:8000/sign/packages/myguid")
		Ω(e).ShouldNot(HaveOccurred())
		Expect(response.StatusCode).To(Equal(http.StatusOK))

		signedUrl, e := ioutil.ReadAll(response.Body)
		Ω(e).ShouldNot(HaveOccurred())

		response, e = http.Get(string(signedUrl))
		Ω(e).ShouldNot(HaveOccurred())
		Expect(ioutil.ReadAll(response.Body)).To(ContainSubstring("lalala"))
	})

})

func NewPutRequest(url string, formFiles map[string]map[string]io.Reader) *http.Request {
	if len(formFiles) > 1 {
		panic("More than one formFile is not supported yet")
	}
	bodyBuf := &bytes.Buffer{}
	request, e := http.NewRequest("PUT", url, bodyBuf)
	Ω(e).ShouldNot(HaveOccurred())
	header := AddFormFileTo(bodyBuf, formFiles)
	AddHeaderTo(request, header)
	return request
}

func AddHeaderTo(request *http.Request, header http.Header) {
	for key, values := range header {
		for _, value := range values {
			request.Header.Add(key, value)
		}
	}
}

func AddFormFileTo(body io.Writer, formFiles map[string]map[string]io.Reader) (header http.Header) {
	header = make(map[string][]string)
	for name, fileAndReader := range formFiles {
		multipartWriter := multipart.NewWriter(body)
		for file, reader := range fileAndReader {
			formFileWriter, e := multipartWriter.CreateFormFile(name, file)
			Ω(e).ShouldNot(HaveOccurred())
			io.Copy(formFileWriter, reader)
			multipartWriter.Close()
			header["Content-Type"] = append(header["Content-Type"], multipartWriter.FormDataContentType())
		}
	}
	return
}

func GetStatusCode(response *http.Response) int { return response.StatusCode }
