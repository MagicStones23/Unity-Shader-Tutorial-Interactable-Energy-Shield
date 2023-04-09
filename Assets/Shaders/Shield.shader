Shader "Tutorial/Shield"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (0, 0, 0, 0)
        
        _RimPower ("RimPower", Float) = 1
        [HDR] _RimColor ("RimColor", Color) = (1, 1, 1, 1)

        _IntersectionWidth ("IntersectionWidth", Float) = 1
        [HDR] _IntersectionColor ("IntersectionColor", Color) = (1, 1, 1, 1)
        
        _PatternTex ("PatternTex", Cube) = "white" {}
        _PatternPower ("PatternPower", Float) = 1
        [HDR] _PatternColor ("PatternColor", Color) = (1, 1, 1, 1)

        _Mask ("Mask", 2D) = "black" {}
        [HDR] _MaskColor ("MaskColor", Color) = (1, 1, 1, 1)
        
        _Noise ("Noise", 2D) = "white" {}

        _DissolveThreshold ("DissolveThreshold", Float) = 1
        _DissolveWidth ("DissolveWidth", Float) = 0.1
        [HDR] _DissolveColor ("DissolveColor", Color) = (1, 1, 1, 1)

        _DistortNormal ("DistortNormal", 2D) = "bump" {}
        _DistortIntensity ("DistortIntensity", Float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }

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
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 binormal : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                float4 screenPos : TEXCOORD5;
                float4 localPos : TEXCOORD6;
            };

            float4 _BaseColor;
            
            float _RimPower;
            float4 _RimColor;

            float _IntersectionWidth;
            float4 _IntersectionColor;

            samplerCUBE _PatternTex;
            float _PatternPower;
            float4 _PatternColor;
            
            sampler2D _Mask;
            float4 _Mask_ST;
            float4 _MaskColor;

            float _DissolveThreshold;
            float _DissolveWidth;
            float4 _DissolveColor;

            int _InteractionNumber;
            float3 _InteractionStartPosArray[100];
            float _InteractionInnerRadiusArray[100];
            float _InteractionOuterRadiusArray[100];
            float _InteractionAlphaArray[100];
            float4 _InteractionColorArray[100];
            
            float _DistortAlphaArray[100];

            sampler2D _DistortNormal;
            float4 _DistortNormal_ST;
            float _DistortIntensity;

            sampler2D _Noise;
            float4 _Noise_ST;

            sampler2D _CameraDepthTexture;

            float GetInteractionIntensity(v2f i, float3 startPos, float innerRadius, float outerRadius) {
                float dist = distance(i.worldPos, startPos);
                if(dist > outerRadius || dist < innerRadius) {
                    return 0;
                }
                else {
                    float intensity = (dist - innerRadius) / (outerRadius - innerRadius);
                    intensity = saturate(intensity);
                    return intensity;
                }
            }

            float GetDistortIntensity(v2f i, float3 startPos, float innerRadius, float outerRadius) {
                float dist = distance(i.worldPos, startPos);
                if(dist > outerRadius) {
                    return 0;
                }
                else {
                    float intensity = dist / outerRadius;
                    intensity = saturate(intensity);
                    return intensity;
                }
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.tangent = TransformObjectToWorldDir(v.tangent.xyz);
                o.normal = TransformObjectToWorldNormal(v.normal.xyz);
                o.binormal = cross(o.tangent, o.normal) * v.tangent.w;

                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.localPos = v.vertex;
                o.screenPos = o.vertex;
                #if UNITY_UV_STARTS_AT_TOP
                o.screenPos.y *= -1;
                #endif
                return o;
            }

            float4 frag (v2f i) : SV_Target0
            {
                float4 finalColor = _BaseColor;

                int isFrontFace = 1;

                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float ndv = dot(normal, viewDir);
                if(ndv < 0) {
                    ndv = abs(ndv);
                    isFrontFace = 0;
                }
                ndv = 1 - ndv;

                float rimIntensity = pow(abs(ndv), _RimPower);
                finalColor += _RimColor * rimIntensity;
                finalColor.a = saturate(finalColor.a);





                float interactionIntensity = 0;
                float4 interactionColor = 0;
                float distortIntensity = 0;
                for(int iii = 0; iii < _InteractionNumber; iii++) {
                    float tempInteractionIntensity = GetInteractionIntensity(i, _InteractionStartPosArray[iii], _InteractionInnerRadiusArray[iii], _InteractionOuterRadiusArray[iii]) * _InteractionAlphaArray[iii];
                    interactionIntensity += tempInteractionIntensity;

                    interactionColor += _InteractionColorArray[iii] * tempInteractionIntensity;

                    distortIntensity += GetDistortIntensity(i, _InteractionStartPosArray[iii], _InteractionInnerRadiusArray[iii], _InteractionOuterRadiusArray[iii]) * _DistortAlphaArray[iii];
                    distortIntensity = saturate(distortIntensity);
                }

                interactionIntensity = saturate(interactionIntensity);

                finalColor += interactionColor;
                finalColor.a = saturate(finalColor.a);





                float3x3 tangentToWorld = float3x3(
                    i.tangent.x, i.normal.x, i.binormal.x,
                    i.tangent.y, i.normal.y, i.binormal.y,
                    i.tangent.z, i.normal.z, i.binormal.z
                );

                float3 distortNormal = UnpackNormal(tex2D(_DistortNormal, i.uv * _DistortNormal_ST.xy + _DistortNormal_ST.zw * _Time.y));
                distortNormal = mul(tangentToWorld, distortNormal);
                distortNormal *= _DistortIntensity * distortIntensity * 3;





                float patternIntensity = texCUBE(_PatternTex, normal + distortNormal).a * isFrontFace;
                patternIntensity *= pow(abs(ndv + interactionIntensity * 2), _PatternPower);
                finalColor += patternIntensity * _PatternColor;
                finalColor.a = saturate(finalColor.a);





                float mask = 0;
                mask += tex2D(_Mask, i.uv * _Mask_ST.xx + _Mask_ST.zz * _Time.y).a;
                mask += tex2D(_Mask, i.uv * _Mask_ST.yy + _Mask_ST.ww * _Time.y).a;
                mask = saturate(mask);
                finalColor += patternIntensity * mask * _MaskColor;
                finalColor.a = saturate(finalColor.a);





                i.screenPos.xyz /= i.screenPos.w;
                float2 screenUV = i.screenPos.xy;
                screenUV = (screenUV + 1) / 2;

                float selfZ = i.screenPos.z;
                float sceneZ = tex2D(_CameraDepthTexture, screenUV).r;
                float linearSelfZ = LinearEyeDepth(selfZ, _ZBufferParams);
                float linearSceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);
                float zDifference = linearSceneZ - linearSelfZ;
                if(zDifference < _IntersectionWidth) {
                    float intersectionIntensity = (1 - zDifference / _IntersectionWidth);
                    intersectionIntensity = saturate(intersectionIntensity);
                    intersectionIntensity = pow(intersectionIntensity, 4);
                    finalColor += _IntersectionColor * intersectionIntensity;
                    finalColor.a = saturate(finalColor.a);
                }







                if(i.localPos.y > _DissolveThreshold) {
                    discard;
                }
                else if(i.localPos.y > _DissolveThreshold - _DissolveWidth) {
                    float t = (i.localPos.y - _DissolveThreshold + _DissolveWidth) / _DissolveWidth;
                    float noise = tex2D(_Noise, i.uv * _Noise_ST.xy + _Noise_ST.zw * _Time.y).r;
                    noise = lerp(1, noise * (1 - t), pow(t, 0.5));
                    if(noise > 0.5) {
                        finalColor = _DissolveColor;
                    }else {
                        discard;
                    }
                }






                return finalColor;
            }
            ENDHLSL
        }
    }
}