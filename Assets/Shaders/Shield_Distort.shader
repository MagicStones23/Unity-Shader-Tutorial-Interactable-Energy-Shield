Shader "Tutorial/Shield_Distort"
{
    Properties
    {
        _DistortNormal ("DistortNormal", 2D) = "bump" {}
        _DistortIntensity ("DistortIntensity", Float) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 worldTangent : TEXCOORD3;
                float3 worldNormal : TEXCOORD4;
                float3 worldBinormal : TEXCOORD5;
            };

            int _InteractionNumber;
            float3 _InteractionStartPosArray[100];
            float _InteractionInnerRadiusArray[100];
            float _InteractionOuterRadiusArray[100];
            float _InteractionAlphaArray[100];
            
            float _DistortAlphaArray[100];

            sampler2D _DistortNormal;
            float4 _DistortNormal_ST;
            float _DistortIntensity;

            sampler2D _CameraOpaqueTexture;
            float4 _CameraOpaqueTexture_TexelSize;

            float GetDistortIntensity(v2f i, float3 startPos, float innerRadius, float outerRadius) {
                float dist = distance(i.worldPos, startPos);
                if(dist > outerRadius) {
                    return 0;
                }
                else {
                    float intensity = dist / outerRadius;
                    intensity *= 2;
                    if(intensity > 1) {
                        intensity = 2 - intensity;
                    }
                    return intensity;
                }
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.screenPos = o.vertex;
                #if UNITY_UV_STARTS_AT_TOP
                o.screenPos.y *= -1;
                #endif
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 finalColor = 0;

                float distortIntensity = 0;
                for(int iii = 0; iii < _InteractionNumber; iii++) {
                    distortIntensity += GetDistortIntensity(i, _InteractionStartPosArray[iii], _InteractionInnerRadiusArray[iii], _InteractionOuterRadiusArray[iii]) * _DistortAlphaArray[iii] * 6;
                    distortIntensity = saturate(distortIntensity);
                }

                float3 distortNormal = UnpackNormal(tex2D(_DistortNormal, i.uv * _DistortNormal_ST.xy + _DistortNormal_ST.zw * _Time.y));
                distortNormal *= _DistortIntensity * distortIntensity;

                i.screenPos.xyz /= i.screenPos.w;
                float2 screenUV = i.screenPos.xy;
                screenUV = (screenUV + 1) / 2;

                finalColor = tex2D(_CameraOpaqueTexture, screenUV + distortNormal.xy * _CameraOpaqueTexture_TexelSize.xy);

                return finalColor;
            }
            ENDHLSL
        }
    }
}