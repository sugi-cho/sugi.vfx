using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;
using UnityEngine.Timeline;

public class VfxTimeCurveParam : MonoBehaviour,ITimeControl
{
    public VisualEffect targetVfx;
    public string propName;
    public AnimationCurve curve;

    public void OnControlTimeStart()
    {
    }

    public void OnControlTimeStop()
    {
    }

    public void SetTime(double time)
    {
        targetVfx.SetFloat(propName, curve.Evaluate((float)time));
    }
}
