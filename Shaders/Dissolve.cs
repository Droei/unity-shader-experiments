using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;

public class Dissolve : MonoBehaviour
{
    [SerializeField] float dissolveTime = .75f;

    MeshRenderer meshRenderer;
    Material material;

    int dissolveAmount = Shader.PropertyToID("dissolveAmount");
    int verticalDissolveAmount = Shader.PropertyToID("verticalDissolveAmount");

    private void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();

        material = meshRenderer.material;
    }

    private void Update()
    {
        if (Keyboard.current.eKey.wasPressedThisFrame)
        {
            StartCoroutine(Vanish());
        }
        else if (Keyboard.current.fKey.wasPressedThisFrame)
        {
            StartCoroutine(Appear());
        }
    }

    private IEnumerator Vanish()
    {
        float elapsedTime = 0f;

        while (elapsedTime < dissolveTime)
        {
            elapsedTime += Time.deltaTime;

            float lerpedDissolve = Mathf.Lerp(0, 1.1f, (elapsedTime / dissolveTime));
            float lerpedVerticalDissolve = Mathf.Lerp(0, 1.1f, (elapsedTime / dissolveTime));

            material.SetFloat(dissolveAmount, lerpedDissolve);
            material.SetFloat(verticalDissolveAmount, lerpedVerticalDissolve);

            yield return null;
        }
    }

    private IEnumerator Appear()
    {
        float elapsedTime = 0f;

        while (elapsedTime < dissolveTime)
        {
            elapsedTime += Time.deltaTime;

            float lerpedDissolve = Mathf.Lerp(1.1f, 0, (elapsedTime / dissolveTime));
            float lerpedVerticalDissolve = Mathf.Lerp(1.1f, 0, (elapsedTime / dissolveTime));

            material.SetFloat(dissolveAmount, lerpedDissolve);
            material.SetFloat(verticalDissolveAmount, lerpedVerticalDissolve);

            yield return null;
        }
    }

}
