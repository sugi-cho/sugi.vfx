//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

sampler3D _DitherMaskLOD;
void DitheringShadow_half(half alpha, half2 screenPos, bool shadowCascaded, out half outAlpha, out half clipThreshold)
{
    outAlpha = alpha;
    clipThreshold = 0;
#if (!defined(SHADERGRAPH_PREVIEW))
    {
        half2 vpos = screenPos * _MainLightShadowmapSize.z;
        vpos *= shadowCascaded ? 0.5 : 1;
        outAlpha = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25, alpha * 0.9375)).a;
        clipThreshold = 0.5;
    }
#endif
}

#ifdef SHADERGRAPH_PREVIEW
#else
half GetAdditionalLightRealtimeShadow(int lightIndex, float3 positionWS)
{
    lightIndex = GetPerObjectLightIndex(lightIndex);
    ShadowSamplingData shadowSamplingData = GetAdditionalLightShadowSamplingData();
    
    float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[lightIndex], float4(positionWS, 1.0));
    half4 shadowParams = GetAdditionalLightShadowParams(lightIndex);
    shadowCoord.xyz /= shadowCoord.w;
    half attenuation = SampleShadowmapFiltered(TEXTURE2D_ARGS(_AdditionalLightsShadowmapTexture, sampler_AdditionalLightsShadowmapTexture), shadowCoord, shadowSamplingData);
    return LerpWhiteTo(attenuation, shadowParams.x);
}
//copy function from Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl
void BlinnPhong(InputData inputData, half3 diffuse, half4 specularGloss, half smoothness,
    out half3 out_MainDiffuse, out half3 out_MainSpeclur, out half out_MainShadow, out half3 out_AdditionalDiffuse, out half3 out_AdditionalSpaclur)
{
    half4 shadowMask = unity_ProbesOcclusion;

    //Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    Light mainLight = GetMainLight();
    
    //Shadow.hlsl
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    half attenuation = SampleShadowmapFiltered(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), inputData.shadowCoord, shadowSamplingData);
    mainLight.shadowAttenuation = attenuation;

    half3 attenuatedLightColor = mainLight.color * mainLight.distanceAttenuation;
    out_MainDiffuse = LightingLambert(attenuatedLightColor, mainLight.direction, inputData.normalWS) * diffuse;
    out_MainSpeclur = LightingSpecular(attenuatedLightColor, mainLight.direction, inputData.normalWS, inputData.viewDirectionWS, specularGloss, smoothness);
    out_MainShadow = mainLight.shadowAttenuation;
    
    out_AdditionalDiffuse = 0;
    out_AdditionalSpaclur = 0;
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        //Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        light.shadowAttenuation = GetAdditionalLightRealtimeShadow(lightIndex, inputData.positionWS);
        
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        out_AdditionalDiffuse += LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS) * diffuse;
        out_AdditionalSpaclur += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, specularGloss, smoothness);
    }
}
#endif

void SimpleLit_half(
half3 positionWS, half3 normalWS, half3 viewDirectionWS,
half3 diffuse, half4 specular, half smoothness,
out half3 out_MainDiffuse, out half3 out_MainSpeclur, out half out_MainShadow, out half3 out_AdditionalDiffuse, out half3 out_AdditionalSpaclur)
{
#ifdef SHADERGRAPH_PREVIEW
    out_MainDiffuse = 1;
    out_MainSpeclur = 0;
    out_MainShadow = 1;
    out_AdditionalDiffuse = 0;
    out_AdditionalSpaclur = 0;
#else
    smoothness = exp2(10 * smoothness + 1);
    half4 positionCS = TransformWorldToHClip(positionWS);
    half cascadeIndex = ComputeCascadeIndex(positionWS);
    half4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));
    
    InputData inputData;
    inputData.positionWS = positionWS;
    inputData.normalWS = normalWS;
    inputData.viewDirectionWS = viewDirectionWS;
    inputData.shadowCoord = shadowCoord;
    inputData.fogCoord = ComputeFogFactor(positionCS.z);
    inputData.vertexLighting = half3(0, 0, 0);
    inputData.bakedGI = 0;
    //inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(positionCS);
    //inputData.shadowMask = half4(1, 1, 1, 1);
    
    BlinnPhong(inputData, diffuse, specular, smoothness, out_MainDiffuse, out_MainSpeclur, out_MainShadow, out_AdditionalDiffuse, out_AdditionalSpaclur);
#endif

}

void GetFinalColor_half(half3 mainDiffuse, half3 mainSpecular, half mainShadow, half3 additionalDiffuse, half3 additionalSpecular, half3 emission, out half3 out_finalColor)
{
    out_finalColor = emission + mainShadow * (mainDiffuse + mainSpecular) + additionalDiffuse + additionalSpecular;

}