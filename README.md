# How to use

<font size=7> This project is create in Unity2022.2 </font>

### Click shield to interact
### Press C to hide shield
### Press O to show shield




https://user-images.githubusercontent.com/129722386/230711633-63775944-1afd-4299-b677-65857372ddb4.mp4



<br/><br/>
<br/><br/>



# Unity Shader Tutorial, Interactable Energy Shield

# Demonstration

https://user-images.githubusercontent.com/129722386/229703054-6ec0d660-cd0c-4f8c-8e60-4735e44672d0.mp4

# Setup URP Project

### Create a new project and switch to Universal RP. I am using Unity2022.2

![0新建工程](https://user-images.githubusercontent.com/129722386/229703456-d031eaec-0684-42f7-96b6-548322403d0b.png)

### Remember to toggle DepthTexture and OpaqueTexture, we will use them later

![1配置URP](https://user-images.githubusercontent.com/129722386/229703492-01d8ba72-67dd-4608-b2d9-ee9de12f11b7.png)

### Create a new shader

![2新建Shader - 副本](https://user-images.githubusercontent.com/129722386/229703527-4243ea39-e7f0-4043-a39e-3464469fcc72.png)

![2新建Shader](https://user-images.githubusercontent.com/129722386/229703554-cb923e80-a693-4899-ac8a-d7b75a0c62bd.png)

### Add uv, normal and other informations for later use

```csharp
struct appdata
{
   float4 vertex : POSITION;
   float2 uv : TEXCOORD0;
   float3 normal : NORMAL;
};

struct v2f
{
   float4 vertex : SV_POSITION;
   float2 uv : TEXCOORD1;
   float3 normal : TEXCOORD2;
   float3 worldPos : TEXCOORD3;
   float4 screenPos : TEXCOORD4;
   float4 localPos : TEXCOORD5;
};

v2f vert (appdata v)
{
   v2f o;
   o.vertex = TransformObjectToHClip(v.vertex.xyz);
   o.uv = v.uv;
   o.normal = TransformObjectToWorldNormal(v.normal);
   o.worldPos = TransformObjectToWorld(v.vertex.xyz);
   o.localPos = v.vertex;
   o.screenPos = o.vertex;
   #if UNITY_UV_STARTS_AT_TOP
    o.screenPos.y *= -1;
   #endif
   return o;
}
```

# Rim Light

### First, add rim light, use dot product of model normal and view direction

```csharp
//Properties
_RimPower ("RimPower", Float) = 1
[HDR] _RimColor ("RimColor", Color) = (1, 1, 1, 1)

float _RimPower;
float4 _RimColor;

//frag
float3 normal = normalize(i.normal);
float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
float ndv = dot(normal, viewDir);
if(ndv < 0) {
   ndv = abs(ndv);
}
ndv = 1 - ndv;

float rimIntensity = pow(ndv, _RimPower);
finalColor += _RimColor * rimIntensity;
finalColor.a = saturate(finalColor.a);
```

![4边缘光](https://user-images.githubusercontent.com/129722386/229703624-2b7bd5e3-a64c-4c14-a085-ca472fab7c27.png)

### Something seems to be missing, oh, forgot to add Bloom

![5Bloom](https://user-images.githubusercontent.com/129722386/229703655-8af354f9-d0c9-490f-93d0-6a43145c4dd8.png)

# Intersection Highlight

### When energy shield contacts with other objects, it needs a bright edge. Sample scene depth texture with pixel screen coordinates, and then compare scene depth with pixel depth. When two value are close enough, a bright edge should be displayed

```csharp
//Properties
_IntersectionWidth ("IntersectionWidth", Float) = 1
[HDR] _IntersectionColor ("IntersectionColor", Color) = (1, 1, 1, 1)

float _IntersectionWidth;
float4 _IntersectionColor;

sampler2D _CameraDepthTexture;

//frag
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
```
![6高亮](https://user-images.githubusercontent.com/129722386/229703689-1e56287a-e86b-4a6c-8f72-eaf752c85c8b.png)

# Texture
### Next, add texture to energy shield, sphere's UV is uneven, if sample texture directly with UV, texture will be compressed at top area and stretched in  middle area.

### Here I transfer 2d texture into a cubemap, sample it with normal vector. And check if pixel is on backface, if it is, no need to show texture

![7Cubemap](https://user-images.githubusercontent.com/129722386/229703827-eb0cff79-3856-4873-9d19-163365ee505d.png)

```csharp
//Properties
_PatternTex ("PatternTex", Cube) = "white" {}
_PatternPower ("PatternPower", Float) = 1
[HDR] _PatternColor ("PatternColor", Color) = (1, 1, 1, 1)

samplerCUBE _PatternTex;
float _PatternPower;
float4 _PatternColor;

//frag
int isFrontFace = 1;
//......
if(ndv < 0) {
   isFrontFace = 0;
}

float patternIntensity = texCUBE(_PatternTex, normal).a * isFrontFace;
patternIntensity *= pow(ndv, _PatternPower);
finalColor += patternIntensity * _PatternColor;
finalColor.a = saturate(finalColor.a);
```
![8纹理](https://user-images.githubusercontent.com/129722386/229703845-cccb40d8-79a9-4e72-8095-4c7963418286.png)

### Next, add flow effect to texture, using a grid mask

![9纹理流动](https://user-images.githubusercontent.com/129722386/229703877-717c5737-a2ce-4724-a2e1-741c0b4364ef.png)

```csharp
//Properties
_Mask ("Mask", 2D) = "black" {}
[HDR] _MaskColor ("MaskColor", Color) = (1, 1, 1, 1)

sampler2D _Mask;
float4 _Mask_ST;
float4 _MaskColor;

//frag
float mask = 0;
mask += tex2D(_Mask, i.uv * _Mask_ST.xx + _Mask_ST.zz * _Time.y).a;
mask += tex2D(_Mask, i.uv * _Mask_ST.yy + _Mask_ST.ww * _Time.y).a;
mask = saturate(mask);
finalColor += patternIntensity * mask * _MaskColor;
finalColor.a = saturate(finalColor.a);
```
https://user-images.githubusercontent.com/129722386/229703904-e705d9f0-7bba-4800-8dce-394141ea8816.mp4

# Dissolve
### Next, add dissolve effect for shield startup, use pixel's  y coordinate to control dissolve, and add a noise texture to make irregular contour

```csharp
//Properties
_Noise ("Noise", 2D) = "white" {}

_DissolveThreshold ("DissolveThreshold", Float) = 1
_DissolveWidth ("DissolveWidth", Float) = 0.1
[HDR] _DissolveColor ("DissolveColor", Color) = (1, 1, 1, 1)

sampler2D _Noise;
float4 _Noise_ST;

float _DissolveThreshold;
float _DissolveWidth;
float4 _DissolveColor;

//frag
if(i.localPos.y > _DissolveThreshold) {
   discard;
}
else if(i.localPos.y > _DissolveThreshold - _DissolveWidth) {
   float t = (i.localPos.y - _DissolveThreshold + _DissolveWidth) / _DissolveWidth;
   float noise = tex2D(_Noise, i.uv * _Noise_ST.xy + _Noise_ST.zw * _Time.y);
   noise = lerp(1, noise * (1 - t), pow(t, 0.5));
   if(noise > 0.5) {
       finalColor = _DissolveColor;
   }else {
       discard;
   }
}
```

https://user-images.githubusercontent.com/129722386/229703986-38a7ffae-b367-47a6-8a7e-b14dc6ff6540.mp4

# Interaction
### Next, make the most complex interaction function. Use C# script to pass interaction data(position, radius, color) to material. Then in shader, calculate the distance between pixel and interaction position, display interaction color if pixel is within interaction radius.

### Create a new script called Shield.cs, which contains APIs that pass informations to material

```csharp
public class Shield : MonoBehaviour {
   private class InteractionData {
       public Color color;
       public Vector3 interactionStartPos;
       public float timer;
   }

   public List<Material> materials;

   private List<InteractionData> interactionDatas = new List<InteractionData>();

   private void Update() {
       //......
        for (int i = 0; i < materials.Count; i++) {
           materials.SetInt("_InteractionNumber", interactionDatas.Count);

           if (interactionDatas.Count > 0) {
               materials.SetVectorArray("_InteractionStartPosArray", interactionStartPosArray);
               materials.SetFloatArray("_InteractionInnerRadiusArray", interactionInnerRadiusArray);
               materials.SetFloatArray("_InteractionOuterRadiusArray", interactionOuterRadiusArray);
               materials.SetFloatArray("_InteractionAlphaArray", interactionAlphaArray);
               materials.SetColorArray("_InteractionColorArray", interactionColorArray);
               materials.SetFloatArray("_DistortAlphaArray", distortAlphaArray);
           }
       }
   }

   public void AddInteractionData(Vector3 pos, Color color) {
       if (interactionDatas.Count >= 100) {
           return;
       }

       InteractionData interactionData = new InteractionData();
       interactionData.color = color;
       interactionData.interactionStartPos = pos;
       interactionDatas.Add(interactionData);
   }
}
```

### Create a new script called ShootManager.cs, which performs ray detection when clicking mouse button and call interaction API if ray collides with energy shield

```csharp
public class ShootManager : MonoBehaviour {
    [ColorUsage(true, true)] public Color interactionColor;

   private void Update() {
       if (Input.GetMouseButtonDown(0)) {
           RaycastHit hitInfo;
           bool hited = Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hitInfo, Mathf.Infinity);
           if (hited) {
               Shield.instance.AddInteractionData(hitInfo.point, interactionColor);
           }
       }
   }
}
```

### Then calculate it in shader

```csharp
//Properties
int _InteractionNumber;
float3 _InteractionStartPosArray[100];
float _InteractionInnerRadiusArray[100];
float _InteractionOuterRadiusArray[100];
float _InteractionAlphaArray[100];
float4 _InteractionColorArray[100];
     
float _DistortAlphaArray[100];

float GetInteractionIntensity(v2f i, float3 startPos, float innerRadius, float outerRadius) {
   float dist = distance(i.worldPos, startPos);
   if(dist > outerRadius || dist < innerRadius) {
       return 0;
   }
   else {
     float intensity = (dist - innerRadius) / (outerRadius - innerRadius);
     return intensity;
   }
}

//frag
float interactionIntensity = 0;
float4 interactionColor = 0;
for(int iii = 0; iii < _InteractionNumber; iii++) {
  float tempInteractionIntensity = GetInteractionIntensity(i, _InteractionStartPosArray[iii], _InteractionInnerRadiusArray[iii], _InteractionOuterRadiusArray[iii]) * _InteractionAlphaArray[iii];
   interactionIntensity += tempInteractionIntensity;

   interactionColor += _InteractionColorArray[iii] * tempInteractionIntensity;
}

interactionIntensity = saturate(interactionIntensity);

finalColor += interactionColor;
finalColor.a = saturate(finalColor.a);
```

https://user-images.githubusercontent.com/129722386/229704069-78d6acb8-a068-49b1-965f-7fe174dabb49.mp4

### In interaction area, lighten and distort the main texture

```csharp
//Properties
_DistortNormal ("DistortNormal", 2D) = "bump" {}
_DistortIntensity ("DistortIntensity", Float) = 1

sampler2D _DistortNormal;
float4 _DistortNormal_ST;
float _DistortIntensity;

float GetDistortIntensity(v2f i, float3 startPos, float innerRadius, float outerRadius) {
   float dist = distance(i.worldPos, startPos);
   if(dist > outerRadius) {
       return 0;
   }
   else {
       float intensity = dist / outerRadius;
       return intensity;
   }
}

//frag
float3 distortNormal = UnpackNormal(tex2D(_DistortNormal, i.uv * _DistortNormal_ST.xy + _DistortNormal_ST.zw * _Time.y));
distortNormal *= _DistortIntensity * distortIntensity;

float distortIntensity = 0;
for(int iii = 0; iii < _InteractionNumber; iii++) {
   //......
    distortIntensity += GetDistortIntensity(i, _InteractionStartPosArray[iii], _InteractionInnerRadiusArray[iii], _InteractionOuterRadiusArray[iii]) * _DistortAlphaArray[iii];
   distortIntensity = saturate(distortIntensity);
}

float patternIntensity = texCUBE(_PatternTex, normal + distortNormal).a * isFrontFace;
patternIntensity *= pow(ndv + interactionIntensity, _PatternPower);
finalColor += patternIntensity * _PatternColor;
finalColor.a = saturate(finalColor.a);
```
https://user-images.githubusercontent.com/129722386/229704120-44c0f44c-1238-422a-a8af-3f5d4945dd58.mp4

### Interaction function is one step away!

### Next, add screen distortion, the idea is to change screen UV with a normal map, then sample _CameraOpaqueTexture

### Create a new shader called Shield_Distort.shader, copy all code from shield shader and add

```csharp
sampler2D _CameraOpaqueTexture;
float4 _CameraOpaqueTexture_TexelSize;
```

### Modify fragment function

```csharp
float4 frag (v2f i) : SV_Target
{
   float4 finalColor = 0;

   float distortIntensity = 0;
   for(int iii = 0; iii < _InteractionNumber; iii++) {
      distortIntensity += GetDistortIntensity(i, _InteractionStartPosArray[iii], _InteractionInnerRadiusArray[iii], _InteractionOuterRadiusArray[iii]) * _DistortAlphaArray[iii];
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
```

### Make a copy of the energy shield with new shader

![13屏幕扭曲](https://user-images.githubusercontent.com/129722386/229706345-75d1efd8-fdc6-467a-9916-50edab5702d4.png)

https://user-images.githubusercontent.com/129722386/229704178-2f85ea83-99d5-4c9b-80a6-d97c30774edc.mp4

### At this point, our energy shield has complete!


# Source Project

https://github.com/MagicStones23/Unity-Shader-Tutorial-Interactable-Energy-Shield

### Note: Some of the texture resources in this project are taken from Internet, do not use them in your commercial project

# My Social Media

Twitter : https://twitter.com/MagicStone23

Youtube : https://www.youtube.com/channel/UCBUXiYqkFy0g6V0mVH1kESw

zhihu : https://www.zhihu.com/people/shui-guai-76-84

Bilibili : https://space.bilibili.com/423191063?spm_id_from=333.1007.0.0
