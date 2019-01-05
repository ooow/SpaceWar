//
//  GameScene.swift
//  SpaceWar
//
//  Created by Goga Tirkiya on 05/01/2019.
//  Copyright © 2019 Goga Tirkiya. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starSpace: SKEmitterNode!;
    var scoreLabel: SKLabelNode!;
    var player: SKSpriteNode!;
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)";
        }
    }
    
    override func didMove(to view: SKView) {
        self.addChild(initStarSpace());
        self.addChild(initScoreLabel());
        self.addChild(initPlayer());
    }
    
    func initStarSpace() -> SKEmitterNode{
        starSpace = SKEmitterNode(fileNamed: "StarSpace");
        starSpace.position = CGPoint(x: 0, y: 1472);
        starSpace.advanceSimulationTime(10);
        starSpace.zPosition = -1;
        return starSpace;
    }
    
    func initPlayer() -> SKSpriteNode {
        player = SKSpriteNode(imageNamed: "shuttle");
        player.position = CGPoint(x: 0, y: -self.frame.size.height / 2 + 150);
        return player;
    }
    
    func initScoreLabel() -> SKLabelNode {
        scoreLabel = SKLabelNode(text: "Score: 0");
        scoreLabel.fontName = "AmericanTypewritter-Bold";
        scoreLabel.fontSize = 36;
        scoreLabel.fontColor = UIColor.white;
        scoreLabel.position = CGPoint(x: -self.frame.size.width / 2 + 80, y: self.frame.size.height / 2 - 40);
        return scoreLabel;
    }
    
    func configureSelf() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0);
        self.physicsWorld.contactDelegate = self;
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
