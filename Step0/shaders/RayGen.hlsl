/* Copyright (c) 2018-2019, NVIDIA CORPORATION. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of NVIDIA CORPORATION nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Common.hlsl"

// ---[ Ray Generation Shader ]---

[shader("raygeneration")]
void RayGen()
{
	uint2 LaunchIndex = DispatchRaysIndex().xy;
	uint2 LaunchDimensions = DispatchRaysDimensions().xy;

	float2 d = (((LaunchIndex.xy + 0.5f) / resolution.xy) * 2.f - 1.f);
	float aspectRatio = (resolution.x / resolution.y);

	// Setup the ray
	RayDesc ray;
	ray.Origin = viewOriginAndTanHalfFovY.xyz;
	ray.Direction = normalize((d.x * view[0].xyz * viewOriginAndTanHalfFovY.w * aspectRatio) - (d.y * view[1].xyz * viewOriginAndTanHalfFovY.w) + view[2].xyz);
	ray.TMin = 0.1f;
	ray.TMax = 1000.f;	

	// Trace the ray - initialize
    HitInfo payload = MakeEmptyHit();

	// Intrinsic Func
	//	어떻게 payload를 등록도 안했는데 바로 되는거지?
	//	https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html#traceray
	//	TODO : inout에 대해서 조사
	TraceRay(
		SceneBVH,
		RAY_FLAG_NONE,
		0xFF,
		0,
		0,
		0,
		ray,
		payload);

    float3 outputColor = payload.ShadedColorAndHitT.rgb;
	bool primaryHit = payload.NormalAndHit.w == 1.0f;
	float3 primaryNormal = payload.NormalAndHit.xyz;

    if (primaryHit)
    {
		//1. normal 렌더링
        //outputColor = 0.5f * (primaryNormal + 1.0f);
        
		//2. Second Ray Hit
        float normalLengthSquared = dot(primaryNormal, primaryNormal);
        if (normalLengthSquared > 1e-20f)
        {
            float3 position = ray.Origin + payload.ShadedColorAndHitT.w * ray.Direction;
            float3 normal = normalize(primaryNormal);
            if (dot(ray.Direction, normal) > 0.0f)
                normal = -normal;

            RayDesc secondaryRay;
            secondaryRay.Origin = position + 0.001f * normal;
            secondaryRay.Direction = normalize(reflect(ray.Direction, normal));
            secondaryRay.TMin = 0.0001f;
            secondaryRay.TMax = 1000.0f;

            HitInfo secondary = MakeEmptyHit();
            TraceRay(SceneBVH, RAY_FLAG_NONE, 0xFF, 0, 0, 0, secondaryRay, secondary);
            outputColor = secondary.ShadedColorAndHitT.rgb;
        }
    }
	RTOutput[LaunchIndex.xy] = float4(outputColor, 1.f);
	
	//<일정 관련>
	//기말고사 일주일 전부터, 기간 중간까지
	//발표 평가 부교수님 시간 맞춰야 하기 때문에
	//3주 안에 MIS 구현을 해야 뒤에 좀 생각해보고 할 수 있는 기간이 있어야 한다
	
	//<프로젝트 방향>
	//문제점 - 한번 반사했을 때 미츠바랑 값이 달랐다
	//정리할 내용이 있어야 한다
	//- 깃허브 파기
	//- 프로젝트 파일 여러개 만들기 (주차별)
	//- 미츠바와의 비교군
	//- 수치같은 부분들도 미츠바에서 가져오기 (엡실론 같은거)
	
	//실습 파일에서 과정별로 잘 되어 있다.
	//파이썬 파일에서 비교군을 만들고 나서, 그 부분을 DX로 옮긴다.
}