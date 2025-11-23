using UnityEngine;
using UnityEngine.InputSystem;

public class User : MonoBehaviour
{
    [SerializeField] InputAction interactAction;

    private void OnEnable()
    {
        interactAction.Enable();
        interactAction.performed += Interact;
    }

    private void OnDisable()
    {
        interactAction.performed -= Interact;
        interactAction.Disable();
    }

    private void Interact(InputAction.CallbackContext context)
    {
        Debug.Log("Interact!");
    }
}
