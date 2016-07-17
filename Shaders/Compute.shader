Shader "CSG/Compute" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Ref ("Ref", Int) = 0
		_Depth1 ("Depth 1", 2D) = "white" {}
		_Depth2 ("Depth 2", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		// PASS 0 -- Draw initial intersecting objects
		Pass {
			ColorMask 0
			ZTest Greater
		}

		// PASS 1 -- Count back-faces of intersecting objects
		Pass {
			ColorMask 0
			Cull Front
			ZWrite Off
			ZTest Always
			Stencil {
				Pass IncrSat
			}
		}

		// PASS 2 -- Mask off pixels not within the intersection
		Pass {
			ColorMask 0
			Cull Off
			ZTest Always
			Stencil {
				Ref [_Ref]
				Pass Zero
				Fail Zero
				ZFail Zero
				Comp NotEqual
			}
		}

		// PASS 3 -- Reset stencil
		Pass {
			ColorMask 0
			ZTest Always
			ZWrite Off
			Stencil {
				Ref 0
				Pass Replace
			}
		}

		// PASS 4
		Pass {
			ColorMask 0
			ZTest Less
			ZWrite Off
			Cull Front
			Stencil {
				Ref 1
				Pass Replace
			}
		}

		// PASS 5
		Pass {
			ColorMask 0
			Cull Off
			ZTest Always
			Stencil {
				Ref 1
				Comp Equal
			}
		}

		// PASS 6
		Pass {
			ColorMask 0
			Cull Off
			ZTest LEqual
			ZWrite Off
			Stencil {
				Ref [_Ref]
				Pass Replace
				Comp Always
			}
		}

		// PASS 7
		Pass {
			ColorMask 0
			Cull Off
			ZTest GEqual
			ZWrite On
			Stencil {
				Ref [_Ref]
				Comp Equal
			}
		}

		CGINCLUDE
		bool feq (float a, float b) {
			return abs(a - b) < 0.001;
		}
		ENDCG

		// PASS 8
		Pass {
			ZWrite Off
			ZTest Equal
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

      sampler2D _CameraDepthTexture;

			struct v2f {
				float4 vertex : SV_POSITION;
				float4 projPos : TEXCOORD0;
				float2 depth : TEXCOORD1;
			};

			v2f vert (appdata_base v) {
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.depth = o.vertex.zw;
				o.projPos = ComputeScreenPos(o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);
				return o;
			}
			
			float2 frag (v2f i) : SV_Target {
				return (float2(i.depth.x / i.depth.y,  i.projPos.z - _ProjectionParams.y) * _ProjectionParams.w);
			}
			ENDCG
		}

		// PASS 9
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _Depth1;
			sampler2D _Depth2;

			struct v2f {
				float4 pos : SV_POSITION;
				float4 screenpos : TEXCOORD0;
			};

			v2f vert (appdata_base v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.screenpos = ComputeScreenPos(o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				float2 uv = float2(i.screenpos.x / i.screenpos.w, i.screenpos.y / i.screenpos.w);
				float d1 = tex2D(_Depth1, uv).g;
				float d2 = tex2D(_Depth2, uv).g;
				fixed4 c = tex2D(_MainTex, uv);
				clip(d2 < d1 ? 1 : -1);
				return c;
			}
			ENDCG
		}

		// PASS 10
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _Depth1;
			sampler2D _Depth2;

			struct v2f {
				float4 pos : SV_POSITION;
				float4 screenpos : TEXCOORD0;
			};

			v2f vert (appdata_base v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.screenpos = ComputeScreenPos(o.pos);
				return o;
			}
			
			float2 frag (v2f i) : SV_Target {
				float2 uv = float2(i.screenpos.x / i.screenpos.w, i.screenpos.y / i.screenpos.w);
				float2 d1 = tex2D(_Depth1, uv);
				float2 d2 = tex2D(_Depth2, uv);
				if (d1.r < d2.r)
					return d1;
				else
					return d2;
			}
			ENDCG
		}

		// PASS 11
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _Depth1;
			sampler2D _CameraDepthTexture;

			struct v2f {
				float4 vertex : SV_POSITION;
				float4 projPos : TEXCOORD0;
			};

			v2f vert (appdata_base v) {
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.projPos = ComputeScreenPos(o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				float2 uv = float2(i.projPos.x / i.projPos.w, i.projPos.y / i.projPos.w);
				float4 pp =  _ProjectionParams.w;
				float d1 = tex2D(_Depth1, uv).g;
				float d2 = (LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))) - pp.y) * pp.w;
				fixed4 c = tex2D(_MainTex, uv);
				clip(d1 < d2 ? 1 : -1);
				return c;
			}
			ENDCG
		}

	}
	FallBack "Diffuse"
}
