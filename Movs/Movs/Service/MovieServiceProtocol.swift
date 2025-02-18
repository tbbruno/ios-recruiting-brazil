//
//  MovieServiceProtocol.swift
//  Movs
//
//  Created by Bruno Barbosa on 26/10/19.
//  Copyright © 2019 Bruno Barbosa. All rights reserved.
//

import Foundation

enum APIError: String {
    case genericError = "An error has occurred, please try again."
}

protocol MovieServiceProtocol {
    static var shared: MovieServiceProtocol { get }
    var popularMovies: [Movie] { get }
    var favoriteMovies: [Movie] { get }
    
    func fetchPopularMovies(completion: @escaping MoviesListCompletionBlock)
    func fetchFavoriteMovies(completion: MoviesListCompletionBlock?)
    func toggleFavorite(for movie: Movie, completion: SuccessOrErrorCompletionBlock?)
    func isFavorite(movie: Movie) -> Bool
    func getGenresString(for movie: Movie) -> String
}
