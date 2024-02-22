//
//  MiniMapView.swift
//  Assignment 2
//
//  Created by Delaine Tan on 2024-02-21.
//
import UIKit

class MiniMapView: UIView {
    
    // Define the size of a single cell in the minimap
    let cellSize: CGFloat = 10.0
    
    // Define properties to represent the maze
    var maze: Maze? {
        didSet {
            setNeedsDisplay() // Redraw the view when maze is set
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard var maze = maze else {
            print("Maze is nil")
            return
        }
        
        // Get the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Iterate through maze cells
        for row in 0..<maze.rows {
            for col in 0..<maze.cols {
                let cell = maze.GetCell(Int32(row), Int32(col))
                
                // Calculate cell frame
                let cellFrame = CGRect(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
                
                // Draw cell
                if cell.northWallPresent || cell.southWallPresent || cell.eastWallPresent || cell.westWallPresent {
                    context.setFillColor(UIColor.gray.cgColor)
                } else {
                    context.setFillColor(UIColor.green.cgColor)
                }
                context.fill(cellFrame)
            }
        }
    }
}
