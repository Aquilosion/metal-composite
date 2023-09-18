//
//  Shaders.metal
//  MetalComposite
//
//  Created by Robert Pugh on 2023-09-17.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
	float2 position  [[attribute(0)]];
	float4 color     [[attribute(1)]];
};

struct VertexOut {
	float4 position  [[position]];
	float4 color;
};

vertex VertexOut vertexShader(
	VertexIn vertexIn [[stage_in]]
) {
	VertexOut vertexOut;
	vertexOut.position = float4(vertexIn.position, 0, 1);
	vertexOut.color = vertexIn.color;
	
	return vertexOut;
}

fragment float4 fragmentShader(
	VertexOut fragmentIn [[stage_in]]
) {
	return fragmentIn.color;
}
