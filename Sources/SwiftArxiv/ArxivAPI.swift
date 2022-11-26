import Foundation
import SwiftSoup

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public struct ArxivAPI {
    private static let taxonomyURL: URL = URL(string: "https://arxiv.org/category_taxonomy")!
    
    /// Returns arXiv's [cateogry taxonomy](https://arxiv.org/category_taxonomy)
    ///
    /// ArXiv organizes various subjects (e.g. Computer Science, Mathematics) into a taxonomy. Each subject has various categories (e.g. Machine Learning) that have unique identifiers (e.g. cs.LG).
    /// - Returns: ArXiv's taxonomy as a dictionary [Subject: [(Category ID, Category Name)]]
    public static func getTaxonomy() async -> Dictionary<String, [(String, String)]>? {
        guard let taxonomyHTML: String = await fetch(url: self.taxonomyURL) else {
            return nil
        }
        do {
            let document: Document = try SwiftSoup.parse(taxonomyHTML)
            // <div id="cateogry_taxonomy_list" ...>...</div>
            let taxonomyElement: Element? = try document.getElementById("category_taxonomy_list")
            // <h2 class="accordion-head ...">{{ subject }}</h2>
            if let subjectElements = try taxonomyElement?.getElementsByClass("accordion-head") {
                var taxonomy: Dictionary<String, [(String, String)]> = [:]
                for subjectElement in subjectElements {
                    let subject: String = try subjectElement.text()
                    taxonomy[subject] = []
                    // #accordion-head.nextElementSibling => #accordion-body
                    // #column #is-one-fifth => <h4>{{ cateogry.identifier }}<span>({{ category.name }})</span> </h4>
                    if let categoryElements = try subjectElement.nextElementSibling()?.getElementsByClass("column is-one-fifth") {
                        for categoryElement in categoryElements {
                            // {{ category.identifier }} ({{ category.name }})
                            let categoryText = try categoryElement.child(0).text()
                            let splits = categoryText.split(separator: " (")
                            guard splits.count == 2 else {
                                continue
                            }
                            // {{ category.identifier }}
                            let id: String = String(splits[0])
                            // {{ category.name }}
                            let category: String = String(splits[1].dropLast())
                            
                            taxonomy[subject]?.append((id, category))
                        }
                    }
                }
                return taxonomy
            }
            return nil
        } catch {
            return nil
        }
    }
}

// Given a URL, fetches the html content as a string
@available(macOS 12.0, *)
@available(iOS 15.0, *)
private func fetch(url: URL) async -> String? {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return nil
        }
        if let mimeType = httpResponse.mimeType, mimeType == "text/html",
           let htmlString = String(data: data, encoding: .utf8) {
            return htmlString
        }
    } catch {
        return nil
    }
    return nil
}
