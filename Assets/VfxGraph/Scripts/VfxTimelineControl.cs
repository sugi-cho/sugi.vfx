using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Timeline;
using UnityEngine.VFX;
using UnityEngine.Events;

public class VfxTimelineControl : MonoBehaviour, ITimeControl
{
    public VisualEffect targetVfx;
    public string timeStartEvent = "Spawn";
    public string timeStopEvent = "Stop";
    public bool reinitOnstart = false;
    public bool sendStartEvent = true;
    public bool sentStopEvent = true;

    [Header("Additional Events")]
    public UnityEvent onTimeStart;
    public UnityEvent onTimeStop;
    public TimeEvent onTimeSet;

    void Reset()
    {
        var vfx = GetComponent<VisualEffect>();
        if (vfx != null)
            targetVfx = vfx;
    }

    public void OnControlTimeStart()
    {
        if (reinitOnstart)
            targetVfx.Reinit();
        onTimeStart.Invoke();
        if (sendStartEvent)
            targetVfx.SendEvent(timeStartEvent);
    }

    public void OnControlTimeStop()
    {
        onTimeStop.Invoke();
        if (sendStartEvent)
            targetVfx.SendEvent(timeStopEvent);
    }

    public void SetTime(double time)
    {
        onTimeSet.Invoke((float)time);
    }

    [System.Serializable]
    public class TimeEvent : UnityEvent<float> { }
}
