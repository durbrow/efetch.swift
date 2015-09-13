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
        
        init(function: String, params: [String:String]) {
            let comp = NSURLComponents()
            
            comp.scheme = "http"
            comp.host = "eutils.ncbi.nlm.nih.gov"
            comp.path = "/entrez/eutils/\(function).fcgi"
            comp.queryItems = params.map { NSURLQueryItem(name: $0.0, value: $0.1) }
            
            url = comp.URL!
        }
        
        var description: String { get { return url.description } }
    }
    private static func searchURL(term: String, database: String) -> URL {
        return URL(
            function: "esearch",
            params  : [
                "db"        : database,
                "retmode"   : "json",
                "term"      : term,
            ]
        )
    }
    private static func fetchURL(gi: String, database: String) -> URL {
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
    private static func search(term: String, database: String) throws -> [String] {
        let url = EUtils.searchURL(term, database: database).url
        for ;; {
            let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions())
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
            guard let resp = json as? [String:AnyObject] else { break }
            guard let rslt = resp["esearchresult"] as? [String:AnyObject] else { break }
            guard let gilist = rslt["idlist"] as? [AnyObject] else { break }
            return gilist.map { $0 as! String }
        }
        return []
    }
    public static func FASTA(accession: String, f: (String) -> Bool) throws
    {
        let gilist = try EUtils.search(accession, database: "nuccore")
        guard gilist.count > 0 else { return }
        let url = fetchURL(gilist[0], database: "nuccore").url
        try String(contentsOfURL: url, encoding: NSUTF8StringEncoding).enumerateLines { (line, inout stop: Bool) in
            stop = f(line)
        }
    }
}


