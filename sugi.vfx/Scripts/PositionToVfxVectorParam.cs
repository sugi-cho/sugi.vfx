using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

namespace sugi.cc.vfx
{
    public class PositionToVfxVectorParam : MonoBehaviour
    {
        public VisualEffect targetVfx;
        public string param = "SpawnPos";
        public Space space = Space.World;

        private void OnDrawGizmos()
        {
            var resetMatrix = Gizmos.matrix;
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.DrawWireCube(Vector3.zero, Vector3.one * 0.5f);
            Gizmos.DrawLine(Vector3.left, Vector3.right);
            Gizmos.DrawLine(Vector3.back, Vector3.forward);
            Gizmos.DrawLine(Vector3.zero, Vector3.up);
            Gizmos.matrix = resetMatrix;
        }

        public void SetParam()
        {
            if (space == Space.World)
                targetVfx.SetVector3(param, transform.position);
            else if (space == Space.Self)
                targetVfx.SetVector3(param, transform.localPosition);
            Debug.Log("set pos");
        }
    }
}