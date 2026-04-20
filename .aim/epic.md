# Epic: Lock all availability

Mode: Strict
Cost profile: Cost Control

Make the Lock all button communicate when it is useful.

Desired behavior:
- Lock all is greyed out and unavailable when fewer than two floating candidate numbers exist.
- Lock all becomes available when two or more candidate numbers exist.
- The store should also guard against accidental lock-all execution while disabled.
