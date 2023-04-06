using System.Collections;
using System.Collections.Generic;
using UnityEngine;

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