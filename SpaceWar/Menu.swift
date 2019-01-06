//
//  Menu.swift
//  SpaceWar
//
//  Created by Goga Tirkiya on 06/01/2019.
//  Copyright © 2019 Goga Tirkiya. All rights reserved.
//

import SpriteKit

class Menu: SKScene {
    var starSpace : SKEmitterNode!;
    
    var newGameButton: SKSpriteNode!;
    var levelButton: SKSpriteNode!;
    var labelLevel: SKLabelNode!;
    
    override func didMove(to view: SKView) {
        starSpace = (self.childNode(withName: "starSpaceAnimation") as! SKEmitterNode);
        starSpace.advanceSimulationTime(10);
        
        newGameButton = (self.childNode(withName: "newGameButton") as! SKSpriteNode);
        levelButton = (self.childNode(withName: "levelButton") as! SKSpriteNode);
        labelLevel = (self.childNode(withName: "labelLevenButton") as! SKLabelNode);
        
        let userLevel = UserDefaults.standard;
        
        if userLevel.bool(forKey: "hard") {
            labelLevel.text = "HARD";
        } else {
            labelLevel.text = "EASY";
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first;
        
        if let location = touch?.location(in: self) {
            let nodesArray = self.nodes(at: location);
            
            if nodesArray.first?.name == "newGameButton" {
                let transition = SKTransition.flipVertical(withDuration: 0.5);
                let gameScene = GameScene(size: UIScreen.main.bounds.size);
                self.view?.presentScene(gameScene, transition: transition);
            } else if nodesArray.first?.name == "levelButton" {
                changeLevel();
            }
        }
    }
    
    func changeLevel(){
        let userLevel = UserDefaults.standard;
        
        if labelLevel.text == "EASY" {
            labelLevel.text = "HARD";
            userLevel.setValue(true, forKey: "hard");
        } else {
            labelLevel.text = "EASY";
            userLevel.setValue(false, forKey: "hard");
        }
        
        userLevel.synchronize();
    }
}
