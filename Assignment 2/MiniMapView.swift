//
//  MiniMapView.swift
//  Assignment 2
//
//  Created by Delaine Tan on 2024-02-21.
//
import UIKit
import SceneKit

class MiniMapView: UIView {
    var mazeRows: Int
    var mazeCols: Int
    var playerPosition: SCNVector3?
    
    init(frame: CGRect, rows: Int, cols: Int, initialPlayerPosition: SCNVector3) {
        self.mazeRows = rows
        self.mazeCols = cols
        super.init(frame: frame)
        self.playerPosition = initialPlayerPosition
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let numRows = mazeRows
        let numCols = mazeCols
        
        let cellWidth = rect.width / CGFloat(numCols)
        let cellHeight = rect.height / CGFloat(numRows)
        
        // Draw grid lines
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        
        // Draw vertical lines
        for col in 0..<numCols {
            let x = CGFloat(col) * cellWidth
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
            context.strokePath()
        }
        
        // Draw horizontal lines
        for row in 0..<numRows {
            let y = CGFloat(row) * cellHeight
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
            context.strokePath()
        }
    }
    
    func updatePlayerPosition(_ newPosition: SCNVector3) {
        playerPosition = newPosition
        print(playerPosition)
    }
}

