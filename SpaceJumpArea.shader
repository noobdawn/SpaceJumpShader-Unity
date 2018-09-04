// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/SpaceJumpArea"
{
	Properties
	{
		//拉扯的力度
		_Jitter ("Jitter", Range(0, 0.1)) = 0.1
		//拉扯的粒度
		_Density("Density", Range(1, 100)) = 50
		//拉扯的频率
		_TimeScale("TimeScale", Range(0, 100)) = 1
		//中心保持平静的区域门槛
		_Threshold("Threshold", Range(0, 1)) = 0.35
	}
	SubShader
	{
		//在所有不透明对象之后绘制，防止出现天空球抓取不到的问题
		Tags { "RenderType"="Transparent" }
		//抓取已渲染的部分到缓存中
		GrabPass { "_SpaceTexture" }
		//裁剪表面，只显示背面
		Cull Front
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "noiseSimplex.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 modelPos : TEXCOORD2;
			};

			sampler2D _SpaceTexture;
			float _Density;
			float _Jitter;
			float _TimeScale;
			float _Shake;
			float _Threshold;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.modelPos = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//snoise来自
				//2D / 3D / 4D optimised Perlin Noise Cg/HLSL library (cginc) - Unity Forum
				//https://forum.unity.com/threads/2d-3d-4d-optimised-perlin-noise-cg-hlsl-library-cginc.218372/
				//获取拉扯幅度分布
				float noise = snoise(float2(atan(i.modelPos.x / i.modelPos.y) * _Density, _Time.y * _TimeScale));
				//获取拉扯的方向
				float3 dir = normalize(float3(0,0,1) - i.modelPos.xyz);
				float d = abs(dot(dir, normalize(i.modelPos)));
				//根据拉扯的方向和球心到球面方向的点积，判断拉扯的程度，为中心部分制造一片不需要拉扯的平静区域
				float needDraw = abs(d - _Threshold);
				needDraw = needDraw + (1 - step(needDraw, 1)) * needDraw;
				//拉扯GrabPass里存下的缓存
				float4 grabuv = ComputeGrabScreenPos(UnityObjectToClipPos(float4(i.modelPos.xyz + dir * noise * _Jitter * needDraw, 1)));
				float4 col = tex2Dproj(_SpaceTexture, grabuv);
				return float4(col.xyz, 1);
			}
			ENDCG
		}
	}
}
