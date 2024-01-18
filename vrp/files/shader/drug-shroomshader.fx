/// <class>ParametricEdgeDetection</class>

/// <description>Pixel shader: Edge detection using a parametric, symetric, directional convolution kernel</description>


// Parameters

/// <summary>The threshold of the edge detection.</summary>
/// <minValue>0</minValue>
/// <maxValue>2</maxValue>
/// <defaultValue>0.5</defaultValue>
float Threshhold = 0.5;

/// <summary>Kernel first column top. Default is the Sobel operator.</summary>
/// <minValue>-10</minValue>
/// <maxValue>10</maxValue>
/// <defaultValue>1</defaultValue>
float K00 = -5.33;

/// <summary>Kernel first column middle. Default is the Sobel operator.</summary>
/// <minValue>-10</minValue>
/// <maxValue>10</maxValue>
/// <defaultValue>2</defaultValue>
float K01 = 1.9;

/// <summary>Kernel first column bottom. Default is the Sobel operator.</summary>
/// <minValue>-10</minValue>
/// <maxValue>10</maxValue>
/// <defaultValue>1</defaultValue>
float K02 = -0.52;

/// <summary>The size of the texture.</summary>
/// <minValue>1,1</minValue>
/// <maxValue>2048,2048</maxValue>
/// <defaultValue>512,512</defaultValue>
float2 TextureSize = float2(1280,720);
float alpha = 0.0;

// Static Vars
static float ThreshholdSq = Threshhold * Threshhold;
static float2 TextureSizeInv = 1.0 / TextureSize;
static float K20 = -K00; // Kernel last column top
static float K21 = -K01; // Kernel last column middle
static float K22 = -K02; // Kernel last column bottom
texture ScreenTexture;

sampler TexSampler = sampler_state
{
    Texture = <ScreenTexture>;
};

// Shader
float4 main(float2 uv : TEXCOORD) : COLOR
{
	// Calculate pixel offsets
    float2 offX = float2(TextureSizeInv.x, 0);
    float2 offY = float2(0, TextureSizeInv.y);

    // Sample texture
	// Top row
	float2 texCoord = uv - offY;
    float4 c00 = {0,0,0,1}; c00 += tex2D(TexSampler, texCoord - offX);
    float4 c01 = {0,0,0,1}; c01 += tex2D(TexSampler, texCoord);
    float4 c02 = {0,0,0,1}; c02 += tex2D(TexSampler, texCoord + offX);

	// Middle row
	texCoord = uv;
    float4 c10 = {0,0,0,1}; c10 += tex2D(TexSampler, texCoord - offX);
    float4 c12 = {0,0,0,1}; c12 += tex2D(TexSampler, texCoord + offX);

	// Bottom row
	texCoord = uv + offY;
    float4 c20 = {0,0,0,1}; c20 += tex2D(TexSampler, texCoord - offX);
    float4 c21 = {0,0,0,1}; c21 += tex2D(TexSampler, texCoord);
    float4 c22 = {0,0,0,1}; c22 += tex2D(TexSampler, texCoord + offX);

    // Convolution
    float4 sx = 0;
    float4 sy = 0;

	// Convolute X
    sx += c00 * K00;
    sx += c01 * K01;
    sx += c02 * K02;
    sx += c20 * K20;
    sx += c21 * K21;
    sx += c22 * K22;

	// Convolute Y
    sy += c00 * K00;
    sy += c02 * K20;
    sy += c10 * K01;
    sy += c12 * K21;
    sy += c20 * K02;
    sy += c22 * K22;

	// Add and apply Threshold
    float4 s = sx * sx + sy * sy;
    float4 edge = {0,0,0,1};
    edge =  1 - float4(	s.r <= ThreshholdSq,
					    s.g <= ThreshholdSq,
					    s.b <= ThreshholdSq,
					    alpha); // Alpha is always 1!

    return edge;
}

    technique Technique1
    {
        pass Pass1
        {
            PixelShader = compile ps_2_a main();
        }
    }
