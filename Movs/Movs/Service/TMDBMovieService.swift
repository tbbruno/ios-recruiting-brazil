//
//  TMDBMovieService.swift
//  Movs
//
//  Created by Bruno Barbosa on 26/10/19.
//  Copyright © 2019 Bruno Barbosa. All rights reserved.
//

import Foundation

struct APIConfiguration {
    
}

class TMDBMovieService: MovieServiceProtocol {
    private init() {
        self.fetchGenresList()
    }
    static private(set) var shared: MovieServiceProtocol = TMDBMovieService()
    
    private(set) var popularMovies: [Movie] = []
    private(set) var favoriteMovies: [Movie] = []
    private(set) var genres: [Int : Genre] = [:]
    private var fetchedFavoriteMovies: Bool = false
    private var favoriteIds: [Int : Bool] = [:]
    
    private func urlRequestFor(path: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.themoviedb.org"
        urlComponents.path = "/3\(path)"
        let apiKeyItem = URLQueryItem(name: "api_key", value: "fc6b049905f30ded698536f6721cc0b1")
        urlComponents.queryItems = [apiKeyItem]
        guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
        let request = URLRequest(url: url)
        return request
    }
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        return session
    }()
    private lazy var favoritsDocumentUrl: URL = {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url.appendingPathComponent("favorites.json")
        } else {
            fatalError("Could not retrieve documents directory")
            // TODO: deal with this error
        }
    }()
    
    // MARK: MovieServiceProtocol functions
    
    func fetchPopularMovies(completion: @escaping MoviesListCompletionBlock) {
        if !self.fetchedFavoriteMovies {
            self.fetchFavoriteMovies(completion: nil)
        }
        
        let request = self.urlRequestFor(path: "/movie/popular")
        
        let task = self.urlSession.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                if let _ = responseError {
                    completion(.genericError, [])
                } else if let jsonData = responseData {
                    let decoder = JSONDecoder()
                    do {
                        let response = try decoder.decode(APIResponse.self, from: jsonData)
                        self.popularMovies = response.results
                        completion(nil, self.popularMovies)
                    } catch {
                        completion(.genericError, [])
                    }
                }
            }
        }
        task.resume()
    }
    
    func fetchFavoriteMovies(completion: MoviesListCompletionBlock?) {
        let fileExists = FileManager.default.fileExists(atPath: self.favoritsDocumentUrl.path)
        if !fileExists || self.fetchedFavoriteMovies {
            completion?(nil, self.favoriteMovies)
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: self.favoritsDocumentUrl)
            let movies = try decoder.decode([Movie].self, from: data)
            
            for movie in movies {
                self.favoriteIds[movie.id] = true
            }
            
            self.favoriteMovies = movies
            self.fetchedFavoriteMovies = true
            completion?(nil, self.favoriteMovies)
        } catch {
            completion?(.genericError, [])
        }
    }
    
    func toggleFavorite(for movie: Movie, completion: SuccessOrErrorCompletionBlock?) {
        var isFavorite = self.isFavorite(movie: movie)
        if (isFavorite) {
            self.favoriteMovies.removeAll { (curMovie) -> Bool in
                curMovie.id == movie.id
            }
        } else {
            self.favoriteMovies.append(movie)
        }
        
        isFavorite = !isFavorite
        self.favoriteIds[movie.id] = isFavorite
        NotificationCenter.default.post(name: .didUpdateFavoritesList, object: self)
        
        self.saveFavoritesToDisk(completion: completion)
        completion?(true, nil)
    }
    
    func isFavorite(movie: Movie) -> Bool {
        let isFavorite = self.favoriteIds[movie.id] ?? false
        return isFavorite
    }
    
    func getGenresString(for movie: Movie) -> String {
        let movieGenres:[String] = movie.genreIds.map { (genreId) -> String in
            return self.genres[genreId]?.name ?? ""
        }
        return movieGenres.joined(separator: ", ")
    }
    
    // MARK: Private fuctions
    
    private func saveFavoritesToDisk(completion: SuccessOrErrorCompletionBlock?) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self.favoriteMovies)
            try data.write(to: self.favoritsDocumentUrl)
            completion?(true, nil)
            
        } catch {
            completion?(false, .genericError)
        }
    }
    
    private func fetchGenresList() {
        let request = self.urlRequestFor(path: "/genre/movie/list")
        
        let task = self.urlSession.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                if let error = responseError {
                    // TODO: handle this error
                    print("genres response error", error)
                } else if let jsonData = responseData {
                    let decoder = JSONDecoder()
                    do {
                        let response = try decoder.decode(GenreResponse.self, from: jsonData)
                        let genres = response.genres
                        for genre in genres {
                            self.genres[genre.id] = genre
                        }
                    } catch {
                        // TODO: handle this error
                        print("genres catch error ", error)
                    }
                }
            }
        }
        task.resume()
    }
}
