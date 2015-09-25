//
//  efetch.swift
//  efetch
//
//  Created by Kenneth Durbrow on 9/12/15.
//  Copyright © 2015 Kenneth Durbrow. All rights reserved.
//

import Foundation

public struct EUtils {
    private struct URL : CustomStringConvertible {
        let url: NSURL
        
        init(function: String, params: [String:String])
        {
            let comp = NSURLComponents()
            
            comp.scheme = "http"
            comp.host = "eutils.ncbi.nlm.nih.gov"
            comp.path = "/entrez/eutils/\(function).fcgi"
            comp.queryItems = params.map { NSURLQueryItem(name: $0.0, value: $0.1) }
            
            url = comp.URL!
        }
        
        var description: String { get { return url.description } }
    }
}

private extension EUtils {
    static func searchURL(term: String, database: String) -> URL
    {
        return URL(
            function: "esearch",
            params  : [
                "db"        : database,
                "retmode"   : "json",
                "term"      : term,
            ]
        )
    }
    static func summaryURL(gi: String, database: String) -> URL
    {
        return URL(
            function: "esummary",
            params  : [
                "db"        : database,
                "retmode"   : "json",
                "id"        : gi,
            ]
        )
    }
    static func fetchURL(gi: String, database: String) -> URL
    {
        return URL(
            function: "efetch",
            params  : [
                "db"        : database,
                "retmode"   : "text",
                "rettype"   : "fasta",
                "id"        : gi,
            ]
        )
    }
}

private extension EUtils {
    static func search(term: String, database: String) -> [String]
    {
        let url = searchURL(term, database: database).url
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
    static func summary(accession: String) throws -> [String:AnyObject]
    {
        let gilist = search(accession, database: "nuccore")
        guard gilist.count > 0 else { return [:] }
        let url = summaryURL(gilist[0], database: "nuccore").url
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
        let gilist = search(accession, database: "nuccore")
        guard gilist.count > 0 else { return }
        let url = fetchURL(gilist[0], database: "nuccore").url
        try String(contentsOfURL: url, encoding: NSUTF8StringEncoding).enumerateLines { (line, inout stop: Bool) in
            stop = f(line)
        }
    }
}
