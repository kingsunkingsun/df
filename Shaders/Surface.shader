Shader "CSG/Surface" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Flip ("Flip", Int) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		ZWrite Off
		ZTest Equal

		Cull Off

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		#pragma vertex vert
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		int _Flip;

		void vert (inout appdata_full v) {
			if (_Flip) v.normal *= -1;
    }

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
		}
		ENDCG

	}
	FallBack "Diffuse"
}
