//
//  GridView.swift
//  MetalComposite
//
//  Created by Robert Pugh on 2023-09-17.
//

import UIKit

final class GridView: UIView {
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		backgroundColor = UIColor(patternImage: UIImage(named: "grid")!)
	}
}
