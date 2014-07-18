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

import XCTest
import UIKit
import AeroGearPush

class AGDeviceRegistrationTests: XCTestCase {
    
    override func setUp() {
        StubManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
                return true
            }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
                return StubResponse(data:NSData.data(),
                    statusCode: 200, headers: ["Content-Type" : "text/json"])
            }))

        super.setUp()
    }
    
    override func tearDown() {
        StubManager.removeAllStubs()
        
        super.tearDown()
    }
    
    func testRegistrationWithServerShouldWork() {
        
        // async test expectation
        let registrationExpectation = expectationWithDescription("UPS registration");
        
        // setup registration
        let registration = AGDeviceRegistration(serverURL: NSURL(string: "http://server.com"))
        
        // attemp to register
        registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!) -> () in

            // setup configuration
            clientInfo.deviceToken = "dummy_token_for_testing_purposes".dataUsingEncoding(NSUTF8StringEncoding) // dummy token
            clientInfo.variantID = "8bd6e6a3-df6b-466c-8292-ed062f2427e8"
            clientInfo.variantSecret = "1c9a6066-e0e5-4bcb-ab78-994335f59874"
            
            // apply the token, to identify THIS device
            let currentDevice = UIDevice()
            
            // --optional config--
            // set some 'useful' hardware information params
            clientInfo.operatingSystem = currentDevice.systemName
            clientInfo.osVersion = currentDevice.systemVersion
            clientInfo.deviceType = currentDevice.model
            clientInfo.alias = "registered from swift"
            },
            
            success: {() -> () in
                registrationExpectation.fulfill()
            },
            
            failure: {(error: NSError!) -> () in
                XCTAssertTrue(false, "should have register")
                
                registrationExpectation.fulfill()
            })
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
