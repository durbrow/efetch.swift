//
//  efetch.swift
//  efetch
//
//  Created by Kenneth Durbrow on 9/12/15.
//  Copyright © 2015 Kenneth Durbrow. All rights reserved.
//

import Foundation

public struct EUtils {
}

extension EUtils {
    static func URL(function: String, params: [String : String]) -> NSURL
    {
        let comp = NSURLComponents()
        
        comp.scheme = "http"
        comp.host = "eutils.ncbi.nlm.nih.gov"
        comp.path = "/entrez/eutils/\(function).fcgi"
        comp.queryItems = params.map { NSURLQueryItem(name: $0.0, value: $0.1) }
        
        return comp.URL!
    }
    static func searchURL(term: String, database: String) -> NSURL
    {
        return URL("esearch",
            params  : [
                "db"        : database,
                "retmode"   : "json",
                "term"      : term,
            ]
        )
    }
    static func summaryURL(gi: String, database: String) -> NSURL
    {
        return URL("esummary",
            params  : [
                "db"        : database,
                "retmode"   : "json",
                "id"        : gi,
            ]
        )
    }
    static func fetchURL(gi: String, database: String) -> NSURL
    {
        return URL("efetch",
            params  : [
                "db"        : database,
                "retmode"   : "text",
                "rettype"   : "fasta",
                "id"        : gi,
            ]
        )
    }
}

extension EUtils {
    static func IDList(database: String, term: String) -> [String]
    {
        let url = searchURL(term, database: database)
        guard
            let data = try? NSData(contentsOfURL: url, options: []),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            let resp = json as? [String:AnyObject],
            let rslt = resp["esearchresult"] as? [String:AnyObject],
            let gilist = rslt["idlist"] as? [String]
            else { return [] }
        return gilist
    }
}

public extension EUtils {
    static func summary(database: String, accession: String) -> [String:AnyObject]
    {
        let gilist = IDList(database, term: accession)
        guard gilist.count > 0 else { return [:] }
        let url = summaryURL(gilist[0], database: database)
        guard
            let data = try? NSData(contentsOfURL: url, options: []),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            let resp = json as? [String:AnyObject],
            let rslt = resp["result"] as? [String:AnyObject],
            let byId = rslt[gilist[0]] as? [String:AnyObject]
            else { return [:] }
        return byId
    }
}

public extension EUtils {
    static func FASTA(accession: String, f: (String) -> Bool) throws
    {
        let gilist = IDList("nuccore", term: accession)
        guard gilist.count > 0 else { return }
        let url = fetchURL(gilist[0], database: "nuccore")
        try String(contentsOfURL: url, encoding: NSUTF8StringEncoding).enumerateLines { (line, inout stop: Bool) in
            stop = f(line)
        }
    }
}

func extractRunAttributes(escapedXML: String) -> [EUtils.Run]
{
    let xml = escapedXML.stringByReplacingOccurrencesOfString("&lt;", withString: "<")
                        .stringByReplacingOccurrencesOfString("&gt;", withString: ">")
                        .stringByReplacingOccurrencesOfString("&amp;", withString: "&")

    class parserDelegate: NSObject, NSXMLParserDelegate {
        var runs : [EUtils.Run] = []
        
        @objc func parser(_: NSXMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String : String]) {
            if element == "Run" && attributes["acc"] != nil {
                runs.append(EUtils.Run(attr: attributes))
            }
        }
    }
    let d = parserDelegate()
    let p = NSXMLParser(data: xml.dataUsingEncoding(NSUTF8StringEncoding)!)
    
    p.delegate = d
    if p.parse() {
        return d.runs
    }
    return []
}

public extension EUtils {
    public struct Run : CustomStringConvertible {
        private let attr: [String : String]
        
        public var accession: String {
            get {
                return attr["acc"]!
            }
        }
        public var baseCount: UInt {
            get {
                if let x = attr["total_bases"], y = UInt(x) { return y }
                return 0
            }
        }
        public var spotCount: UInt {
            get {
                if let x = attr["total_spots"], y = UInt(x) { return y }
                return 0
            }
        }
        public var isLoaded: Bool {
            get {
                if let x = attr["load_done"] where x == "true" { return true }
                return false
            }
        }
        public var isPublic: Bool {
            get {
                if let x = attr["is_public"] where x == "true" { return true }
                return false
            }
        }
        public var description: String { get { return attr.description } }
    }
    static func SRARunList(term: String) -> [Run]
    {
        var rslt = [Run]()
        for id in IDList("sra", term: term) {
            let s = summary("sra", accession: id)
            if let runs = s["runs"] as? String {
                rslt.appendContentsOf(extractRunAttributes(runs))
            }
        }
        return rslt
    }
}
