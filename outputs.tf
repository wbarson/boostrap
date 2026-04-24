output "vm_summary" {
  description = "Summary of all created VMs"
  value = {
    for name, vm in proxmox_vm_qemu.vm : name => {
      vmid        = vm.vmid
      name        = vm.name
      node        = vm.target_node
      cores       = vm.cores
      memory      = vm.memory
      description = "VM ${vm.name} on node ${vm.target_node}"
    }
  }
}

output "vm_ids" {
  description = "Map of VM names to their IDs"
  value = {
    for name, vm in proxmox_vm_qemu.vm : name => vm.vmid
  }
}

output "all_vms" {
  description = "Complete VM resource details"
  value       = proxmox_vm_qemu.vm
  sensitive   = false
}
