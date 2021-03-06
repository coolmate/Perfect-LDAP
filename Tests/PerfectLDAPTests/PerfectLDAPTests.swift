import XCTest
@testable import PerfectLDAP
import Foundation
import PerfectICONV
import OpenLDAP

/*
 Note of setup testing environments:
 * Windows 2000 Advanced Server: Domain Controller with DNS Server, 
  Only Support Simple Login, PORT 389
 * Windows 2003 / 2008 Server: Support FULL functions, with SSL PORT 636
  Active Directory Domain Services
  Active Directory Lightweight Directory Services
  DNS Server
  Identity Management for UNIX
 * Windows 2008 SSL Configuration: Choose Certificate Template of Kerberos V and
 * Then duplicate into LDAPoverSSL, import it to Local Computer Service Account.
 * as described in
 * https://social.technet.microsoft.com/wiki/contents/articles/2980.ldap-over-ssl-ldaps-certificate.aspx
 * mac: /etc/openldap/ldap.conf / linux: /etc/ldap/ldap.conf
 * MUST ADD: `TLS_REQCERT allow`
 */
class PerfectLDAPTests: XCTestCase {
  let testURL = "ldaps://192.168.56.15:636"
  let testBDN = "CN=judy,CN=Users,DC=perfect,DC=com"
  let testUSR = "DN:CN=judy,CN=Users,DC=perfect,DC=com"
  let testATH = "judy"
  let testPWD = "0penLDAP"
  let testRLM = "PERFECT.COM"
  let testBAS = "CN=Users,DC=perfect,DC=com"
  let testCPG: Iconv.CodePage = .UTF8

  let testGSSAPI_URL = "ldap://ipa.demo1.freeipa.org"
  let testGSSAPI_BAS = "DC=demo1,DC=freeipa,DC=org"
  let testGSSAPI_USR = "employee"

  func testLoginGSSAPI() {
    let cred = LDAP.Login(user: testGSSAPI_USR, mechanism: .GSSAPI)
    do {
      let ldap = try LDAP(url: testGSSAPI_URL, loginData: cred)
      let res = try ldap.search(base: testGSSAPI_BAS, scope:.SUBTREE)
      print(res)
    }catch(let err) {
      XCTFail("testLogin error: \(err)")
    }
  }//end testLoginFailed

  func testLoginPass() {
    let cred = LDAP.Login(binddn: testBDN, password: testPWD)
    do {
      let logsuc = expectation(description: "logsuc")
      let ldap = try LDAP(url: testURL)
      ldap.login(info: cred) { err in
        XCTAssertNil(err)
        logsuc.fulfill()
        print("log real passed")
      }//end log
      waitForExpectations(timeout: 10) { error in
        XCTAssertNil(error)
      }//end wait
    }catch(let err) {
      XCTFail("testLogin error: \(err)")
    }
  }//end testLogin

  func testSearch () {
    let cred = LDAP.Login(binddn: testBDN, password: testPWD)
    do {
      let ldap = try LDAP(url: testURL, loginData:cred, codePage: testCPG)

      let ser = expectation(description: "search")
      ldap.search(base:testBAS, scope:.SUBTREE) { res in
        print(res)
        ser.fulfill()
      }//end search

      waitForExpectations(timeout: 10) { error in
        XCTAssertNil(error)
      }
    }catch(let err) {
      XCTFail("error: \(err)")
    }
  }

  func testServerSort () {
    let cred = LDAP.Login(binddn: testBDN, password: testPWD)
    do {
      let ldap = try LDAP(url: testURL, loginData:cred, codePage: testCPG)
      print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
      let sort = LDAP.sortingString(sortedBy: [("description", .ASC)])
      print(sort)
      let res = try ldap.search(base:testBAS,scope:.SUBTREE, attributes: ["displayName", "description"], sortedBy: sort)
      print(res)
    }catch(let err) {
      XCTFail("server control: \(err)")
    }

  }

  func testAttributeMod () {
    let cred = LDAP.Login(binddn: testBDN, password: testPWD)
    do {
      let ldap = try LDAP(url: testURL, loginData:cred, codePage: testCPG)
      let rs = try ldap.search(base:testBDN, scope:.SUBTREE)
      print("=======================================================")
      print(rs)
      print("=======================================================")
      let mod = expectation(description: "modify")
      ldap.modify(distinguishedName: testBDN, attributes: ["codePage":["437"]]) { err in
        mod.fulfill()
        XCTAssertNil(err)
      }//end add
      self.waitForExpectations(timeout: 10){ error in
        XCTAssertNil(error)
      }
      let res = try ldap.search(base:testBDN, scope:.SUBTREE)
      print("=======================================================")
      print(res)
      print("=======================================================")
    }catch(let err) {
      XCTFail("error: \(err)")
    }

  }


  static var allTests : [(String, (PerfectLDAPTests) -> () throws -> Void)] {
    return [
      ("testLoginGSSAPI", testLoginGSSAPI),
      ("testLoginPass", testLoginPass),
      ("testSearch", testSearch),
      ("testAttributeMod", testAttributeMod),
      ("testServerSort", testServerSort),
    ]
  }
}
