// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Blinn-Phong Build-In Function"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", Range(8.0, 256.0)) = 20.0
	}
	SubShader
	{
		Pass
		{
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
//				o.worldNormal = mul(v.normal, (float3x3)_World2Object); // 以下三种写法也都可以
				o.worldNormal = UnityObjectToWorldNormal(v.normal); // 效果相同，因为是矢量变换，用3x3变换矩阵即可。
//				o.worldNormal = mul(v.normal, _World2Object);
//				o.worldNormal = mul(float4(v.normal, 0), _World2Object).xyz;
//				o.worldPos = UnityObjectToWorldDir(v.vertex); // normalize(mul((float3x3)_Object2World, dir));效果与下一行不同
//				o.worldPos = mul(v.vertex, transpose(_Object2World)).xyz; // 将坐标左乘，将模型空间坐标转换到世界空间，与下式相等
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // 将坐标右乘，将模型空间坐标转换到世界空间
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir, worldNormal)) , _Gloss);
				fixed3 color = ambient + diffuse + specular;
				return fixed4(color, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Specular"
}
