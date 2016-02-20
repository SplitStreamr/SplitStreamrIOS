//
//  NetworkFacade.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import Starscream

protocol NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData);
    func sessionIdReceived(sessionId: String);
    func errorRecieved(error: NSError);
    func didEstablishConnection();
}

class NetworkFacade : NSObject {

    let restDataAccessor : NetworkingAccessor;
    let socketMessageParser : SocketMessageParser;
    
    var delegate : NetworkFacadeDelegate?;
    
    let socketURL = "ws://104.236.219.58:8080";
    let socket : WebSocket;
    
    var currentSessionId: String?;
    
    var expectedChunk : (songId: String, chunkNumber: Int)?;
    
    override init() {
        // TODO: pass data accessor and socket to use in the init method
        restDataAccessor = RestNetworkAccessor();
        socketMessageParser = SocketMessageParser();
        socket = WebSocket(url: NSURL(string: socketURL)!);
        
        super.init();
        socketInit();
    }
    
    convenience init(delegate: NetworkFacadeDelegate) {
        self.init();
        
        self.delegate = delegate;
    }
    
    func getSongs(completionBlock: SongArrayClosure) {
        restDataAccessor.getSongs(completionBlock);
    }
    
    func createNewSession() {
        let sessionCreate = ["message" : "new session"];
        
        if let string = String.stringFromJson(sessionCreate) {
            socket.writeString(string);
        }
    }
    
    func connectToSession(sessionId: String) {
        let sessionConnect = ["message" : "join session", "session" : sessionId];
        
        if let string = String.stringFromJson(sessionConnect) {
            socket.writeString(string);
        }
    }
    
    func disconnectFromCurrentSession() {
        socket.disconnect();
    }
    
    func startStreamingSong(songId: String) {
        if let sessionId = currentSessionId {
            let songStream = ["message" : "stream song", "session" : sessionId, "song" : songId];
            
            if let string = String.stringFromJson(songStream) {
                socket.writeString(string);
            }
        }
        else {
            delegate?.errorRecieved(NSError(localizedDescription: "unable to stream song. no valid session active"));
        }
    }
    
    // MARK:
    
    private func socketInit() {
        socketMessageParser.delegate = self;
        socket.delegate = self;
        socket.connect();
    }
    
    // MARK: Chunk Management
    
    private func didReceiveChunk(chunkData: NSData) {
        if let (songId, chunkNumber) = expectedChunk {
            delegate?.musicPieceReceived(songId, chunkNumber: chunkNumber, musicData: chunkData);
            
            respondWithChunkRecieved(songId, chunkNumber: chunkNumber);
            expectedChunk = nil;
        }
    }
    
    private func respondWithChunkRecieved(songId: String, chunkNumber: Int) {
        if let sessionId = currentSessionId {
            let chunkReceived = ["message" : "chunk received", "session" : sessionId, "song" : songId, "chunk" : chunkNumber];
            
            if let string = String.stringFromJson(chunkReceived) {
                socket.writeString(string);
            }
        }
    }
}

// MARK: Message Parser Delegate

extension NetworkFacade : SocketMessageParserDelegate {
    func didCreateSession(sessionId: String) {
        currentSessionId = sessionId;
        delegate?.sessionIdReceived(sessionId);
    }
    
    func didJoinSession(sessionId: String) {
        currentSessionId = sessionId;
        delegate?.sessionIdReceived(sessionId);
    }
    
    func willRecieveChunk(songId: String, chunkNumber: Int) {
        self.expectedChunk = (songId, chunkNumber);
    };
    
    func didFailWithError(error: NSError) {
        delegate?.errorRecieved(error);
    }
}

// MARK: Web Socket Delegate

extension NetworkFacade : WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("socket connected: \(socket)");
        delegate?.didEstablishConnection();
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("socket disconnected \(socket), with error: \(error)");
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("socket message recieved: \(text)");
        socketMessageParser.parseJsonString(text);
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("socket recieved data");
        didReceiveChunk(data);
        // TODO: Figure out what the data is, and call the appropriate delegate method
    }
}
