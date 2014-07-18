/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

class StubURLProtocol: NSURLProtocol {
    
    let stubDescr: StubDescriptor

    override class func canInitWithTask(task: NSURLSessionTask!) -> Bool {
        return StubManager.sharedManager.firstStubPassingTestForRequest(task.currentRequest) != nil
    }

    init(request: NSURLRequest!, cachedResponse: NSCachedURLResponse!, client: NSURLProtocolClient!) {
        stubDescr = StubManager.sharedManager.firstStubPassingTestForRequest(request)!
        
        // ensure no cache response is used
        super.init(request: request, cachedResponse: nil, client: client)
    }

    override class func canonicalRequestForRequest(request: NSURLRequest!) -> NSURLRequest! {
        return request
    }
    
    override func startLoading() {
        let request: NSURLRequest = self.request
        let client: NSURLProtocolClient = self.client;

        let responseStub: StubResponse = self.stubDescr.responseBlock(request)
        
        let urlResponse = NSHTTPURLResponse(URL: request.URL, statusCode: responseStub.statusCode, HTTPVersion: "HTTP/1.1", headerFields: responseStub.headers)
        
        // TODO
        // cookies handling
        //
        
        // handle redirect
        var redirectLocationURL: NSURL? = nil
        
        if let redirectLocation = responseStub.headers["Location"] {
            redirectLocationURL = NSURL.URLWithString(redirectLocation)
        }
        
        if (responseStub.statusCode >= 300 && responseStub.statusCode < 400) && redirectLocationURL {
            let redirectRequest = NSURLRequest(URL: redirectLocationURL)
            
            execute_after(responseStub.requestTime) {
                client.URLProtocol(self, wasRedirectedToRequest: redirectRequest, redirectResponse: urlResponse)
                
            }
            
        } else { // normal response
            execute_after(responseStub.requestTime) {
                client.URLProtocol(self, didReceiveResponse: urlResponse, cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed)
                client.URLProtocol(self, didLoadData: responseStub.data)
                client.URLProtocolDidFinishLoading(self)
            }
        }
    }
    
    func execute_after(delayInSeconds: NSTimeInterval, block: dispatch_block_t) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64( delayInSeconds * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);

    }
}