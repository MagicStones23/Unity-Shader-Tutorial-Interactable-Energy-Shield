using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DissolveManager : MonoBehaviour {
    public float duration = 1f;
    public Material material;
    public AnimationCurve curve;

    private float timer;
    private Action currentAction;

    private void OnDisable() {
        material.SetFloat("_DissolveThreshold", 1);
    }

    private void Update() {
        if (Input.GetKeyDown(KeyCode.O)) {
            timer = 0;
            currentAction = Update_Show;
        }

        if (Input.GetKeyDown(KeyCode.C)) {
            timer = 0;
            currentAction = Update_Hide;
        }

        if (currentAction != null) {
            currentAction.Invoke();
        }
    }

    private void Update_Show() {
        timer += Time.deltaTime;
        float t = curve.Evaluate(Mathf.Clamp01(timer / duration));
        material.SetFloat("_DissolveThreshold", t);
        if (timer > duration) {
            currentAction = null;
        }
    }

    private void Update_Hide() {
        timer += Time.deltaTime;
        float t = curve.Evaluate(1 - Mathf.Clamp01(timer / duration));
        material.SetFloat("_DissolveThreshold", t);
        if (timer > duration) {
            currentAction = null;
        }
    }
}