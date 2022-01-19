//
//  ViewController.swift
//  RetryingNetworkRequests
//
//  Created by Зафар Иваев on 18/01/22.
//

import UIKit
import Combine

enum CustomError: Error {
    case dataCorrupted
    case serverFailure
}

enum State: String {
    case initial = "Initial"
    case loading = "Loading"
    case loadedSuccessfully = "Success"
    case loadingFailed = "Failure"
}

class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    private var cancellables = Set<AnyCancellable>()
    
    @Published var state: State = .initial
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        bindStateToTitle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.bindAvatarToImageView()
        }
        
    }
    
    private func bindStateToTitle() {
        self.$state
            .receive(on: DispatchQueue.main)
            .map { $0.rawValue }
            .assign(to: \.navigationItem.title, on: self)
            .store(in: &cancellables)
    }
    
    private func bindAvatarToImageView() {
        getAvatarFromTheServer()
            .handleEvents(receiveSubscription: { [weak self] in
                print("Subscribed", $0)
                self?.state = .loading
            }, receiveOutput: {
                print("Got image", $0)
            }, receiveCompletion: {
                print("Completion", $0)
            })
            .delay(for: 1, scheduler: DispatchQueue.global())
            .retry(3)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    print("Finished with error: \(error)")
                    self?.state = .loadingFailed
                case .finished:
                    print("Finished")
                }
            }, receiveValue: { [weak self] image in
                self?.imageView.image = image
                self?.state = .loadedSuccessfully
            })
            .store(in: &cancellables)
    }
    
    private func getAvatarFromTheServer() -> AnyPublisher<UIImage, Error> {
        
        let url = URL(string: "https://picsum.photos/corrupted")!
        
        return Deferred {
            Future { promise in
                DispatchQueue.global().async {
                    guard let data = try? Data(contentsOf: url),
                          let image = UIImage(data: data) else {
                              promise(.failure(CustomError.dataCorrupted))
                              return
                          }
                    
                    promise(.success(image))
                }
            }
        }.eraseToAnyPublisher()
    }

}

