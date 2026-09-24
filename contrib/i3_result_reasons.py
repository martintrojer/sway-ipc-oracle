"""Shared reason strings emitted for unclassified i3-suite results."""

NO_TAP_PLAN = "The pinned run emitted no TAP plan; retain this as an environment or harness finding."
INCOMPLETE_RUN = "The pinned run reported environment skips, failures, or assertions it did not reach."
PLACEHOLDER_REASONS = frozenset({NO_TAP_PLAN, INCOMPLETE_RUN})
