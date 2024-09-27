struct DepthPeelingOutput
{
	float4 color : SV_TARGET0;
	float depth : SV_TARGET1;
};

sampler2D _MaxDepthTex;
sampler2D _CameraDepthTexture;
int _DepthPeelingPassCount;

//需要在v2f里定义 float4 screenPos;float4 positionCS;
#define SETUP_DEPTH_PEELING \
DepthPeelingOutput DepthPeelingPixel(v2f input) \
{\
	DepthPeelingOutput output;\
	output.color = RenderPixel(input);\
	output.depth = input.positionCS.z;\
	UNITY_BRANCH if (_DepthPeelingPassCount==0)\
	{\
		return output;\
	}\
	float2 screenUV = input.screenPos /= input.screenPos.w;\
	float lastDepth = tex2D(_MaxDepthTex,screenUV).r;\
	float pixelDepth = input.positionCS.z;\
	if(pixelDepth >= lastDepth) discard;\
	output.color = RenderPixel(input);\
	output.depth = pixelDepth;     \
	return output;\
}\

/*
//需要在v2f里定义 float4 screenPos;float4 positionCS;
DepthPeelingOutput DepthPeelingPixel(v2f input)
{
	DepthPeelingOutput output;
	output.color = RenderPixel(input);
	output.depth = input.positionCS.z;
	//第0帧 直接画颜色与深度
	UNITY_BRANCH if (_DepthPeelingPassCount==0)
		return output;
		
	float2 screenUV = input.screenPos /= input.screenPos.w;
	////上一帧的深度
	float lastDepth = tex2D(_MaxDepthTex,screenUV).r;
	//当前像素的深度
	float pixelDepth = input.positionCS.z;
	//如果当前相机离相机更近，那么丢弃该像素
	if(pixelDepth >= lastDepth) discard;
	            
	return output;
}

Pass
{
	Tags
	{
	"LightMode" = "DepthPeelingPass" "RenderType" = "Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline"
	}

	ZWrite On
	ZTest On
	Cull Off

	HLSLPROGRAM
	#pragma vertex DepthPeelingVertex
	#pragma fragment DepthPeelingPixel
	ENDHLSL
}

*/