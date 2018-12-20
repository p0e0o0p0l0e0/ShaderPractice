// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Single Texture"
{
	Properties
	{
		_Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("Main Tex", 2D) = "white"{}
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

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST; // 纹理名_ST声明了纹理的属性，xy为（平铺）缩放值，zw为偏移值。
			fixed4 _Specular;
			float _Gloss;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal); // 效果相同，因为是矢量变换，用3x3变换矩阵即可。
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // 将坐标右乘，将模型空间坐标转换到世界空间
//				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw; // 对纹理坐标乘以缩放属性，加上偏移属性
				// 假设tiling设置为3，3， offset设置为0.2。那么uv本来是0-1，现在变为0.2到3.2.
				// 如果图片设置成Clamp，那么uv超过1的部分就会按1来算。如果Texture设置成repeat，那么就会去掉整数部分去纹理中采样。
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex); // 等价于上句
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb; // 使用tex2D()对纹理采样，乘以颜色属性得到反射率albedo
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; // 环境光为什么要乘上反射率？？？？？？？？？？
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

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
