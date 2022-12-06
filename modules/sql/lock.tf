# These locks should only engage for deployments to the production env.
# Use the count to validate if it should be engaged.

resource "azurerm_management_lock" "sql_lock" {
    count = local.test_enabled ? 0 : var.sql_count
  name       = "${var.client_name}-sql"
  scope      = azurerm_virtual_machine.sql[count.index].id
  lock_level = "CanNotDelete"
  notes      = "SQL Server"

  lifecycle {
    prevent_destroy = true
  }
}