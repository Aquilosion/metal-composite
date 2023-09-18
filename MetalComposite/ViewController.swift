//
//  ViewController.swift
//  MetalComposite
//
//  Created by Robert Pugh on 2023-09-17.
//

import UIKit
import Metal
import MetalKit
import ModelIO

class ViewController: UIViewController {
	let device = MTLCreateSystemDefaultDevice()!
	var commandQueue: MTLCommandQueue!
	
	var renderView: MTKView!
	
	var renderPipeline: MTLRenderPipelineState!
	
	var vertexDescriptor: MDLVertexDescriptor!
	
	var meshes: [MTKMesh]!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		commandQueue = device.makeCommandQueue()!
		
		loadRenderView()
		loadPipeline()
		loadMeshes()
		
		view.addSubview(renderView)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		renderView.frame = view.bounds
		renderView.setNeedsDisplay()
	}
	
	override var prefersStatusBarHidden: Bool {
		true
	}
	
	private func loadRenderView() {
		renderView = MTKView(frame: view.bounds, device: device)
		
		renderView.colorPixelFormat = .bgra8Unorm_srgb
		renderView.sampleCount = 4
		
		renderView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
		renderView.isOpaque = false
		
		renderView.isPaused = true
		renderView.enableSetNeedsDisplay = true
		
		renderView.delegate = self
	}
	
	private func loadPipeline() {
		let library = device.makeDefaultLibrary()!
		
		let descriptor = MTLRenderPipelineDescriptor()
		descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
		descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
		
		descriptor.sampleCount = 4
		
		let colorAttachmentDescriptor = descriptor.colorAttachments[0]!
		
		colorAttachmentDescriptor.pixelFormat = .bgra8Unorm_srgb
		
		colorAttachmentDescriptor.isBlendingEnabled = true
		colorAttachmentDescriptor.pixelFormat = .bgra8Unorm_srgb
		
		colorAttachmentDescriptor.rgbBlendOperation = .add
		colorAttachmentDescriptor.alphaBlendOperation = .add
		
		colorAttachmentDescriptor.sourceRGBBlendFactor = .sourceAlpha
		colorAttachmentDescriptor.sourceAlphaBlendFactor = .sourceAlpha
		
		colorAttachmentDescriptor.destinationRGBBlendFactor = .oneMinusSourceAlpha
		colorAttachmentDescriptor.destinationAlphaBlendFactor = .oneMinusSourceAlpha

		vertexDescriptor = MDLVertexDescriptor()
		
		vertexDescriptor.attributes = [
			MDLVertexAttribute(
				name: MDLVertexAttributePosition,
				format: .float2,
				offset: 0,
				bufferIndex: 0
			),
			MDLVertexAttribute(
				name: MDLVertexAttributeColor,
				format: .float4,
				offset: MemoryLayout<Float>.size * 2,
				bufferIndex: 0
			)
		]
		
		vertexDescriptor.layouts = [
			MDLVertexBufferLayout(
				stride: MemoryLayout<Float>.size * 6
			)
		]
		
		descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
		
		renderPipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
	}
	
	private func loadMeshes() {
		let allocator = MTKMeshBufferAllocator(device: device)
		
		struct Triangle {
			var position: (SIMD2<Float>, SIMD2<Float>, SIMD2<Float>)
			var color: SIMD4<Float>
		}
		
		let triangles = [
			Triangle(position: (.init(-0.2, 0.8), .init(0.2, 0.8), .init(0, -0.8)), color: .init(1, 1, 1, 1)),
			
			Triangle(position: (.init(0.6, 0.4), .init(0.6, 0.1), .init(-0.6, -0.2)), color: .init(0, 0, 1, 0.5)),
			Triangle(position: (.init(0.6, -0.4), .init(0.6, -0.1), .init(-0.6, 0.2)), color: .init(1, 0, 0, 0.5)),
		]
		
		let meshes = triangles.map { triangle -> MTKMesh in
			var vertexData = (
				triangle.position.0.x, triangle.position.0.y, triangle.color.x, triangle.color.y, triangle.color.z, triangle.color.w,
				triangle.position.1.x, triangle.position.1.y, triangle.color.x, triangle.color.y, triangle.color.z, triangle.color.w,
				triangle.position.2.x, triangle.position.2.y, triangle.color.x, triangle.color.y, triangle.color.z, triangle.color.w
			)
			
			var indexData = (
				0 as UInt8,
				1 as UInt8,
				2 as UInt8
			)
			
			let vertexBuffer = allocator.newBuffer(
				with: Data(bytes: &vertexData, count: MemoryLayout.size(ofValue: vertexData)),
				type: .vertex
			)
			
			let indexBuffer = allocator.newBuffer(
				with: Data(bytes: &indexData, count: MemoryLayout.size(ofValue: indexData)),
				type: .index
			)
			
			let mesh = MDLMesh(
				vertexBuffer: vertexBuffer,
				vertexCount: MemoryLayout.size(ofValue: vertexData) / MemoryLayout<Float>.size,
				descriptor: vertexDescriptor,
				submeshes: [
					MDLSubmesh(
						indexBuffer: indexBuffer,
						indexCount: MemoryLayout.size(ofValue: indexData) / MemoryLayout<UInt8>.size,
						indexType: .uint8,
						geometryType: .triangles,
						material: nil
					)
				]
			)
			
			return try! MTKMesh(mesh: mesh, device: device)
		}
		
		self.meshes = meshes
	}
}

extension ViewController: MTKViewDelegate {
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		
	}
	
	func draw(in view: MTKView) {
		let commandBuffer = commandQueue.makeCommandBuffer()!
		
		let renderPassDescriptor = renderView.currentRenderPassDescriptor!
		
		let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
		
		renderEncoder.setRenderPipelineState(renderPipeline)
		renderEncoder.setCullMode(.none)
		
		for mesh in meshes {
			let vertexBuffer = mesh.vertexBuffers[0]
			renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
			
			for submesh in mesh.submeshes {
				let indexBuffer = submesh.indexBuffer
				
				renderEncoder.drawIndexedPrimitives(
					type: submesh.primitiveType,
					indexCount: submesh.indexCount,
					indexType: submesh.indexType,
					indexBuffer: indexBuffer.buffer,
					indexBufferOffset: indexBuffer.offset
				)
			}
		}
		
		renderEncoder.endEncoding()
		
		commandBuffer.present(renderView.currentDrawable!)
		commandBuffer.commit()
	}
}
