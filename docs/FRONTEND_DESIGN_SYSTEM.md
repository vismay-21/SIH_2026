# Sahakaar Seva Frontend Design System

## Status

Initial mobile design foundation, implemented in the Flutter app on 2026-09-06. This document records the visual decisions made from the supplied reference dashboard and palette.

## Visual direction

The interface is quiet, practical, and cooperative-owned. It uses a warm off-white canvas, white working surfaces, dark green actions, and amber only for attention states such as emergency work. The UI favors clear hierarchy and scanning over decorative cards or dense illustration.

## Palette

| Token | Hex | Use |
| --- | --- | --- |
| Primary | `#245B52` | Main brand, actions, selected navigation |
| Primary dark | `#173B36` | Deep headings and dark emphasis |
| Accent | `#E8B84A` | Emergency and attention states |
| Background | `#F7F8F5` | App canvas |
| Surface | `#FFFFFF` | Cards and form surfaces |
| Text | `#17211F` | Primary copy |
| Muted | `#737C78` | Supporting copy and icons |
| Border | `#D8DDDA` | Dividers and outlines |
| Success | `#3D8B68` | Available, verified, completed states |
| Danger | `#C85C5C` | Error and cancellation states |

The source of truth for these tokens is `mobile_app/lib/theme/app_theme.dart`.

## Typography

The app uses the `Avenir Next` family when available and the platform fallback otherwise. Headings are bold and compact. Supporting copy is muted and uses short, plain-language sentences. No screen should introduce a second font family.

## Components

Shared components currently live in `mobile_app/lib/widgets/common/shared_widgets.dart`:

- `BrandMark` for the product identity.
- `SectionTitle` for repeatable section hierarchy.
- `StatTile` for compact dashboard metrics.
- `StatusPill` for lifecycle and attention labels.
- `PrimaryAction` for high-priority actions.
- `SurfaceCard` for individually framed content.

Cards use a 14px radius and a light outline with no heavy shadow. Buttons use a 10px radius. Icons are Material icons and actions should use icon plus text when the action is not obvious from the icon alone.

## Navigation

Customer navigation is `Home`, `My jobs`, `Alerts`, and `Profile`.

Worker navigation is `Home`, `Opportunities`, `My jobs`, and `Profile`.

This keeps the two role experiences distinct while preserving the project's per-destination folder convention.

## Implemented mock surfaces

- Shared splash and role selection onboarding.
- Customer dashboard with create-gig, emergency, active gig, lifecycle, accepted-worker, and previous-worker surfaces.
- Customer jobs, notifications, and profile destinations.
- Worker dashboard with availability, opportunities, exact wage, current job, and quality surfaces.
- Worker opportunities, jobs, and profile destinations.

These are frontend mock surfaces only. Authentication, wage calculation, recommendation logic, API calls, persistence, and backend state are not implemented here.

## Product constraints kept visible in the UI

- Workers see an exact wage before deciding.
- Customers choose from accepted candidates; there is no bidding UI.
- Emergency work is visually distinct but does not imply automatic assignment.
- Worker verification and availability are represented as separate concepts.
- Lifecycle language is used instead of implying that evidence upload alone completes a gig.

## Next design phases

1. Add reusable forms for create gig, material procurement, and labour range preview.
2. Add worker comparison, recommendation factors, and final selection surfaces.
3. Add completion evidence, customer confirmation, cash/UPI payment, and two-way review surfaces.
4. Add cancellation, rescheduling, multi-worker consent, material proof, and emergency fallback flows.
5. Connect centralized localization resources and replace mock repositories with API-backed repositories when contracts are agreed.
