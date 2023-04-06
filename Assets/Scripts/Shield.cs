using System.Collections;
using System.Collections.Generic;
using System.Security.Cryptography;
using UnityEngine;
using UnityEngine.Rendering;

public class Shield : MonoBehaviour {
    private class InteractionData {
        public Color color;
        public Vector3 interactionStartPos;
        public float timer;
    }





    public static Shield instance;

    public float interactionDuration;
    public float distortDuration;
    public float radius;
    public AnimationCurve curve;
    public List<Material> materials;

    private List<InteractionData> interactionDatas = new List<InteractionData>();

    private void Awake() {
        instance = this;
    }

    private void Update() {
        Vector4[] interactionStartPosArray = new Vector4[100];
        float[] interactionInnerRadiusArray = new float[100];
        float[] interactionOuterRadiusArray = new float[100];
        float[] interactionAlphaArray = new float[100];
        Color[] interactionColorArray = new Color[100];
        float[] distortAlphaArray = new float[100];

        for (int i = 0; i < interactionDatas.Count; i++) {
            InteractionData interactionData = interactionDatas[i];
            if (interactionData.timer > interactionDuration && interactionData.timer > distortDuration) {
                interactionDatas.RemoveAt(i);
                i--;
            }
            else {
                interactionData.timer += Time.deltaTime;

                float interacionT = Mathf.Clamp01(interactionData.timer / interactionDuration);
                float interacionCurveT = curve.Evaluate(interacionT);

                float distortT = Mathf.Clamp01(interactionData.timer / distortDuration);
                float distortCurveT = curve.Evaluate(distortT);

                interactionStartPosArray[i] = interactionData.interactionStartPos;
                interactionInnerRadiusArray[i] = Mathf.Lerp(-radius, radius, interacionCurveT);
                interactionOuterRadiusArray[i] = Mathf.Lerp(0f, radius, interacionCurveT);
                interactionAlphaArray[i] = 1 - interacionCurveT;
                interactionColorArray[i] = interactionData.color;
                distortAlphaArray[i] = 1 - distortCurveT;
            }
        }

        for (int i = 0; i < materials.Count; i++) {
            materials[i].SetInt("_InteractionNumber", interactionDatas.Count);

            if (interactionDatas.Count > 0) {
                materials[i].SetVectorArray("_InteractionStartPosArray", interactionStartPosArray);
                materials[i].SetFloatArray("_InteractionInnerRadiusArray", interactionInnerRadiusArray);
                materials[i].SetFloatArray("_InteractionOuterRadiusArray", interactionOuterRadiusArray);
                materials[i].SetFloatArray("_InteractionAlphaArray", interactionAlphaArray);
                materials[i].SetColorArray("_InteractionColorArray", interactionColorArray);
                materials[i].SetFloatArray("_DistortAlphaArray", distortAlphaArray);
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