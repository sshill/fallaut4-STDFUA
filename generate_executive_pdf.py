#!/usr/bin/env python3
import cairo
import math
import os
import re
import subprocess
import gi
gi.require_version('Pango', '1.0')
gi.require_version('PangoCairo', '1.0')
from gi.repository import Pango, PangoCairo

PAGE_WIDTH = 595.28
PAGE_HEIGHT = 841.89
MARGIN_LEFT = 40.0
MARGIN_RIGHT = 40.0
MARGIN_TOP = 42.0
MARGIN_BOTTOM = 42.0
CONTENT_WIDTH = PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT

WATERMARK_TEXT = "S.Khylevych for Carlo David free for share as, is all rights reserved"

def escape_amp(text):
    return re.sub(r'&(?!(amp|lt|gt|quot|apos);)', '&amp;', text)

class PDFDoc:
    def __init__(self, filename):
        self.filename = filename
        self.surface = cairo.PDFSurface(filename, PAGE_WIDTH, PAGE_HEIGHT)
        self.cr = cairo.Context(self.surface)
        self.pages = []
        self.current_page_ops = []
        self.y = MARGIN_TOP
        self.page_num = 1

    def new_page(self):
        self.pages.append(self.current_page_ops)
        self.current_page_ops = []
        self.y = MARGIN_TOP
        self.page_num += 1

    def check_space(self, height_needed):
        if self.y + height_needed > (PAGE_HEIGHT - MARGIN_BOTTOM):
            self.new_page()

    def add_op(self, op, height, min_space_needed=None):
        space_req = min_space_needed if min_space_needed is not None else height
        self.check_space(space_req)
        cur_y = self.y
        self.current_page_ops.append((op, cur_y))
        self.y += height

    def finalize(self):
        if self.current_page_ops:
            self.pages.append(self.current_page_ops)
        total_pages = len(self.pages)

        for p_idx, page_ops in enumerate(self.pages):
            p_num = p_idx + 1
            # 1. Watermark
            self.draw_watermark()

            # 2. Header
            if p_num > 1:
                self.draw_header()

            # 3. Content
            for op, y_pos in page_ops:
                op(self.cr, y_pos)

            # 4. Footer
            self.draw_footer(p_num, total_pages)

            self.surface.show_page()

        self.surface.finish()

    def draw_watermark(self):
        cr = self.cr
        cr.save()
        cr.translate(PAGE_WIDTH / 2.0, PAGE_HEIGHT / 2.0)
        cr.rotate(-math.radians(35))
        cr.set_source_rgba(0.55, 0.58, 0.65, 0.12)
        layout = PangoCairo.create_layout(cr)
        desc = Pango.FontDescription('Liberation Sans Bold 16.5')
        layout.set_font_description(desc)
        layout.set_text(WATERMARK_TEXT)
        ink, log = layout.get_pixel_extents()
        cr.move_to(-log.width / 2.0, -log.height / 2.0)
        PangoCairo.show_layout(cr, layout)
        cr.restore()

    def draw_header(self):
        cr = self.cr
        cr.save()
        cr.set_source_rgb(0.40, 0.48, 0.58)
        layout = PangoCairo.create_layout(cr)
        desc = Pango.FontDescription('Liberation Sans 8')
        layout.set_font_description(desc)
        layout.set_markup('<b>PROJECT MURQAB AL-SAQR (مرقب الصقر)</b>  |  STRATEGIC EXECUTIVE PROPOSAL')
        cr.move_to(MARGIN_LEFT, 22)
        PangoCairo.show_layout(cr, layout)

        cr.set_source_rgb(0.78, 0.82, 0.88)
        cr.set_line_width(0.75)
        cr.move_to(MARGIN_LEFT, 35)
        cr.line_to(PAGE_WIDTH - MARGIN_RIGHT, 35)
        cr.stroke()
        cr.restore()

    def draw_footer(self, p_num, total_pages):
        cr = self.cr
        cr.save()
        cr.set_source_rgb(0.78, 0.82, 0.88)
        cr.set_line_width(0.75)
        cr.move_to(MARGIN_LEFT, PAGE_HEIGHT - 28)
        cr.line_to(PAGE_WIDTH - MARGIN_RIGHT, PAGE_HEIGHT - 28)
        cr.stroke()

        cr.set_source_rgb(0.40, 0.45, 0.52)
        layout = PangoCairo.create_layout(cr)
        desc = Pango.FontDescription('Liberation Sans 7.5')
        layout.set_font_description(desc)
        layout.set_markup(f'Watermark: <i>{escape_amp(WATERMARK_TEXT)}</i>')
        cr.move_to(MARGIN_LEFT, PAGE_HEIGHT - 20)
        PangoCairo.show_layout(cr, layout)

        layout_p = PangoCairo.create_layout(cr)
        layout_p.set_font_description(desc)
        layout_p.set_markup(f'Page <b>{p_num}</b> of <b>{total_pages}</b>')
        ink, log = layout_p.get_pixel_extents()
        cr.move_to(PAGE_WIDTH - MARGIN_RIGHT - log.width, PAGE_HEIGHT - 20)
        PangoCairo.show_layout(cr, layout_p)

        cr.restore()

def measure_pango(cr, markup, width, font_desc):
    layout = PangoCairo.create_layout(cr)
    layout.set_width(int(width * Pango.SCALE))
    layout.set_wrap(Pango.WrapMode.WORD)
    desc = Pango.FontDescription(font_desc)
    layout.set_font_description(desc)
    layout.set_markup(escape_amp(markup))
    ink, log = layout.get_pixel_extents()
    return log.height

def add_title_banner(doc):
    title_markup = '<span size="17500" weight="bold" foreground="#0F294A">EXECUTIVE STRATEGIC PROPOSAL:\nPROJECT MURQAB AL-SAQR (مرقب الصقر)</span>'
    sub_markup = '<span size="10000" weight="bold" foreground="#C59B27">The Falcon Sentinel: Autonomous High-Altitude Defense &amp; Rapid Evacuation Grid for the Burj Khalifa</span>'
    epigraph = '<i><span size="8200" foreground="#2D3748">“Where ancient Emirati vigilance meets autonomous aerospace engineering: transforming the world’s tallest tower into an unbreachable defensive bastion and an eternal lifeline.”</span></i>'

    h1 = measure_pango(doc.cr, title_markup, CONTENT_WIDTH - 24, 'Liberation Sans Bold 13.5')
    h2 = measure_pango(doc.cr, sub_markup, CONTENT_WIDTH - 24, 'Liberation Sans Bold 9.8')
    h3 = measure_pango(doc.cr, epigraph, CONTENT_WIDTH - 30, 'Liberation Serif Italic 8.8')
    total_h = h1 + h2 + h3 + 26

    def render(cr, y):
        cr.save()
        cr.set_source_rgb(0.96, 0.97, 0.99)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, total_h)
        cr.fill()

        cr.set_source_rgb(0.77, 0.61, 0.15)
        cr.rectangle(MARGIN_LEFT, y, 4, total_h)
        cr.fill()
        cr.set_source_rgb(0.06, 0.16, 0.29)
        cr.rectangle(MARGIN_LEFT + 4, y, 2, total_h)
        cr.fill()

        layout = PangoCairo.create_layout(cr)
        layout.set_width(int((CONTENT_WIDTH - 24) * Pango.SCALE))
        layout.set_wrap(Pango.WrapMode.WORD)
        layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 13.5'))
        layout.set_markup(escape_amp(title_markup))
        cr.move_to(MARGIN_LEFT + 14, y + 6)
        PangoCairo.show_layout(cr, layout)

        layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 9.8'))
        layout.set_markup(escape_amp(sub_markup))
        cr.move_to(MARGIN_LEFT + 14, y + 6 + h1 + 2)
        PangoCairo.show_layout(cr, layout)

        cr.set_source_rgb(0.91, 0.93, 0.96)
        cr.rectangle(MARGIN_LEFT + 14, y + 6 + h1 + h2 + 6, CONTENT_WIDTH - 28, h3 + 6)
        cr.fill()

        layout.set_width(int((CONTENT_WIDTH - 40) * Pango.SCALE))
        layout.set_font_description(Pango.FontDescription('Liberation Serif Italic 8.8'))
        layout.set_markup(escape_amp(epigraph))
        cr.move_to(MARGIN_LEFT + 20, y + 6 + h1 + h2 + 9)
        PangoCairo.show_layout(cr, layout)

        cr.restore()

    doc.add_op(render, total_h + 6)

def add_section_header(doc, number, title):
    clean_title = escape_amp(title.upper())
    markup = f'<span size="10500" weight="bold" foreground="#0F294A">{number}. {clean_title}</span>'
    text_h = measure_pango(doc.cr, markup, CONTENT_WIDTH, 'Liberation Sans Bold 10.2')
    total_h = text_h + 8

    def render(cr, y):
        cr.save()
        layout = PangoCairo.create_layout(cr)
        layout.set_width(int(CONTENT_WIDTH * Pango.SCALE))
        layout.set_wrap(Pango.WrapMode.WORD)
        layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 10.2'))
        layout.set_markup(markup)
        cr.move_to(MARGIN_LEFT, y + 1)
        PangoCairo.show_layout(cr, layout)

        cr.set_source_rgb(0.77, 0.61, 0.15)
        cr.set_line_width(1.5)
        cr.move_to(MARGIN_LEFT, y + text_h + 4)
        cr.line_to(MARGIN_LEFT + 130, y + text_h + 4)
        cr.stroke()

        cr.set_source_rgb(0.85, 0.88, 0.92)
        cr.set_line_width(0.75)
        cr.move_to(MARGIN_LEFT + 135, y + text_h + 4)
        cr.line_to(PAGE_WIDTH - MARGIN_RIGHT, y + text_h + 4)
        cr.stroke()
        cr.restore()

    doc.add_op(render, total_h + 3, min_space_needed=total_h + 45)

def add_subsection_header(doc, title):
    markup = f'<span size="9200" weight="bold" foreground="#1A365D">{escape_amp(title)}</span>'
    h = 15

    def render(cr, y):
        cr.save()
        layout = PangoCairo.create_layout(cr)
        layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 9.0'))
        layout.set_markup(markup)
        cr.move_to(MARGIN_LEFT, y + 1)
        PangoCairo.show_layout(cr, layout)
        cr.restore()

    doc.add_op(render, h, min_space_needed=h + 30)

def add_paragraph(doc, text, spacing_after=4, font_desc='Liberation Sans 8.7'):
    markup = f'<span foreground="#2D3748">{escape_amp(text)}</span>'
    h = measure_pango(doc.cr, markup, CONTENT_WIDTH, font_desc)

    def render(cr, y):
        cr.save()
        layout = PangoCairo.create_layout(cr)
        layout.set_width(int(CONTENT_WIDTH * Pango.SCALE))
        layout.set_wrap(Pango.WrapMode.WORD)
        layout.set_font_description(Pango.FontDescription(font_desc))
        layout.set_markup(markup)
        cr.move_to(MARGIN_LEFT, y)
        PangoCairo.show_layout(cr, layout)
        cr.restore()

    doc.add_op(render, h + spacing_after)

def add_bullet(doc, title, text, spacing_after=3.5):
    full_text = f'<b><span foreground="#0F294A">{escape_amp(title)}:</span></b> <span foreground="#2D3748">{escape_amp(text)}</span>'
    w = CONTENT_WIDTH - 14
    h = measure_pango(doc.cr, full_text, w, 'Liberation Sans 8.5')

    def render(cr, y):
        cr.save()
        cr.set_source_rgb(0.77, 0.61, 0.15)
        cr.arc(MARGIN_LEFT + 4, y + 5.0, 2.2, 0, 2 * math.pi)
        cr.fill()

        layout = PangoCairo.create_layout(cr)
        layout.set_width(int(w * Pango.SCALE))
        layout.set_wrap(Pango.WrapMode.WORD)
        layout.set_font_description(Pango.FontDescription('Liberation Sans 8.5'))
        layout.set_markup(full_text)
        cr.move_to(MARGIN_LEFT + 13, y)
        PangoCairo.show_layout(cr, layout)
        cr.restore()

    doc.add_op(render, h + spacing_after)

def add_ascii_diagram(doc):
    diagram_lines = [
        "                  [ HIGH-ALTITUDE WING-BOX SENTINELS ]",
        "                       (Persistent 800m+ Airborne Node)",
        "                                     ||",
        "                                     ||  <-- Multi-Modal Power & Data Lifeline",
        "                 [ RAPID CLIMBING EVACUATION SHUTTLES ]",
        "                       (Direct High-Speed Facade Access)",
        "                                     ||",
        "                                     ||  <-- Distributed Waveguide Phase Stabilizers",
        "                                     ||",
        "                 [ HEXAGONAL ACTIVE BASE ANCHOR RING ]",
        "                       (6 Shared Pylons Integrated in Landscape)"
    ]
    raw_text = "\n".join(diagram_lines)
    h = len(diagram_lines) * 10.0 + 12

    def render(cr, y):
        cr.save()
        cr.set_source_rgb(0.95, 0.96, 0.98)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, h)
        cr.fill()

        cr.set_source_rgb(0.80, 0.85, 0.90)
        cr.set_line_width(0.75)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, h)
        cr.stroke()

        layout = PangoCairo.create_layout(cr)
        layout.set_font_description(Pango.FontDescription('Liberation Mono 7.2'))
        layout.set_text(raw_text)
        cr.set_source_rgb(0.12, 0.22, 0.35)
        cr.move_to(MARGIN_LEFT + 14, y + 6)
        PangoCairo.show_layout(cr, layout)
        cr.restore()

    doc.add_op(render, h + 6)

def add_exposure_box(doc):
    lines = [
        "+-------------------------------------------------------------------------+",
        "|              EXPOSURE ASSESSMENT WITHOUT PROJECT MURQAB AL-SAQR         |",
        "+-------------------------------------------------------------------------+",
        "|  Human Life Liabilities & Claims  :  $500M - $1.2B                      |",
        "|  Physical Asset Compromise / Loss :  $1.5B - $2.5B                      |",
        "|  Direct Commercial & Retail Halt  :  $2.0B - $3.5B                      |",
        "|  Sovereign Brand & Capital Flight :  $10.0B - $25.0B+                   |",
        "+-------------------------------------------------------------------------+",
        "|  TOTAL QUANTIFIABLE EXPOSURE      :  $14.0B - $32.2B+                   |",
        "+-------------------------------------------------------------------------+"
    ]
    raw_text = "\n".join(lines)
    h = len(lines) * 9.8 + 10

    def render(cr, y):
        cr.save()
        cr.set_source_rgb(0.98, 0.95, 0.95)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, h)
        cr.fill()

        cr.set_source_rgb(0.80, 0.25, 0.25)
        cr.set_line_width(1.0)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, h)
        cr.stroke()

        layout = PangoCairo.create_layout(cr)
        layout.set_font_description(Pango.FontDescription('Liberation Mono 7.0'))
        layout.set_text(raw_text)
        cr.set_source_rgb(0.50, 0.10, 0.10)
        cr.move_to(MARGIN_LEFT + 14, y + 5)
        PangoCairo.show_layout(cr, layout)
        cr.restore()

    doc.add_op(render, h + 5)

def add_table(doc):
    rows = [
        ("Phase 1: Advanced Multiphysics Modeling & Scale Testing",
         "Aeroelastic simulation, wave-damping algorithmic development, scale wind-tunnel validation, and HVDC tether qualification.",
         "$25M – $35M"),
        ("Phase 2: Full Turnkey Manufacturing & Infrastructure",
         "6 complete aerial Wing-Box platforms, 6 mechatronic ground winch pylons, active tether lines, and 6 high-speed rescue shuttles.",
         "$75M – $95M"),
        ("Phase 3: Building Integration & Operational Commissioning",
         "Facade rail alignment, emergency protocol integration with Dubai Civil Defence and UAE Air Force telemetry.",
         "$10M – $15M"),
        ("TOTAL INITIAL CAPITAL EXPENDITURE (CAPEX)",
         "Complete 360° Turnkey Deployment across all 6 Sectors",
         "$110M – $145M"),
        ("ANNUAL OPERATING EXPENDITURE (OPEX)",
         "24/7 flight-readiness, continuous structural telemetry, sensor calibration, and specialized crew operations.",
         "$6M – $9M / yr")
    ]

    col_w = [155.0, 260.0, 100.28]
    pad = 3.8
    header_h = 16.0

    row_heights = []
    for r_idx, (col0, col1, col2) in enumerate(rows):
        is_total = (r_idx >= 3)
        font_style = 'Bold 7.6' if is_total else '7.6'
        h0 = measure_pango(doc.cr, f'<b>{escape_amp(col0)}</b>' if is_total else escape_amp(col0), col_w[0] - 2*pad, f'Liberation Sans {font_style}')
        h1 = measure_pango(doc.cr, f'<b>{escape_amp(col1)}</b>' if is_total else escape_amp(col1), col_w[1] - 2*pad, f'Liberation Sans {font_style}')
        h2 = measure_pango(doc.cr, f'<b>{escape_amp(col2)}</b>' if is_total else escape_amp(col2), col_w[2] - 2*pad, f'Liberation Sans {font_style}')
        rh = max(h0, h1, h2) + 2 * pad
        row_heights.append(rh)

    table_total_h = header_h + sum(row_heights)

    def render(cr, y):
        cr.save()
        cr.set_source_rgb(0.06, 0.16, 0.29)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, header_h)
        cr.fill()

        headers = ["Project Phase / Work Package", "Deliverables & Scope", "Estimated Cost"]
        x = MARGIN_LEFT
        cr.set_source_rgb(1.0, 1.0, 1.0)
        for i, text in enumerate(headers):
            layout = PangoCairo.create_layout(cr)
            layout.set_width(int((col_w[i] - 2*pad) * Pango.SCALE))
            layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 7.6'))
            layout.set_text(text)
            cr.move_to(x + pad, y + 3.0)
            PangoCairo.show_layout(cr, layout)
            x += col_w[i]

        cur_y = y + header_h
        for r_idx, (col0, col1, col2) in enumerate(rows):
            rh = row_heights[r_idx]
            is_total = (r_idx >= 3)

            if is_total:
                cr.set_source_rgb(0.92, 0.94, 0.97)
            elif r_idx % 2 == 1:
                cr.set_source_rgb(0.97, 0.98, 0.99)
            else:
                cr.set_source_rgb(1.0, 1.0, 1.0)
            cr.rectangle(MARGIN_LEFT, cur_y, CONTENT_WIDTH, rh)
            cr.fill()

            cr.set_source_rgb(0.80, 0.84, 0.89)
            cr.set_line_width(0.5)
            cr.move_to(MARGIN_LEFT, cur_y + rh)
            cr.line_to(PAGE_WIDTH - MARGIN_RIGHT, cur_y + rh)
            cr.stroke()

            x0 = MARGIN_LEFT
            layout = PangoCairo.create_layout(cr)
            layout.set_width(int((col_w[0] - 2*pad) * Pango.SCALE))
            layout.set_wrap(Pango.WrapMode.WORD)
            layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 7.4' if is_total else 'Liberation Sans Bold 7.2'))
            layout.set_markup(f'<span foreground="#0F294A">{escape_amp(col0)}</span>')
            cr.move_to(x0 + pad, cur_y + pad)
            PangoCairo.show_layout(cr, layout)

            x1 = x0 + col_w[0]
            layout.set_width(int((col_w[1] - 2*pad) * Pango.SCALE))
            layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 7.2' if is_total else 'Liberation Sans 7.2'))
            layout.set_markup(f'<span foreground="#2D3748">{escape_amp(col1)}</span>')
            cr.move_to(x1 + pad, cur_y + pad)
            PangoCairo.show_layout(cr, layout)

            x2 = x1 + col_w[1]
            layout.set_width(int((col_w[2] - 2*pad) * Pango.SCALE))
            color = "#C59B27" if is_total else "#0F294A"
            layout.set_font_description(Pango.FontDescription('Liberation Sans Bold 7.6'))
            layout.set_markup(f'<span foreground="{color}">{escape_amp(col2)}</span>')
            cr.move_to(x2 + pad, cur_y + pad)
            PangoCairo.show_layout(cr, layout)

            cur_y += rh

        cr.set_source_rgb(0.60, 0.68, 0.76)
        cr.set_line_width(0.75)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, table_total_h)
        cr.stroke()
        cr.restore()

    doc.add_op(render, table_total_h + 6)

def build_pdf(raw_pdf_path):
    doc = PDFDoc(raw_pdf_path)

    # 1. Title Banner
    add_title_banner(doc)

    # 2. Section 1
    add_section_header(doc, "1", "Strategic Context & The Vulnerability of Supertall Assets")
    add_paragraph(doc, "Supertall landmarks—most prominently the <b>Burj Khalifa (828 m)</b>—are the definitive emblems of sovereign prestige, financial leadership, and global ambition for the United Arab Emirates. However, modern urban and regional dynamics present severe asymmetric vulnerabilities:")
    add_bullet(doc, "The High-Rise Isolation Trap", "Standard municipal fire-rescue apparatuses are physically capped at 70 meters. An internal catastrophic event (conflagration, structural failure, utility rupture, or sabotage) above the 50th floor cuts off core elevators, stairwells, and standpipes, trapping hundreds of occupants above the crisis tier with zero external access.")
    add_bullet(doc, "Low-Altitude Standoff Vectors", "Across the maritime expanse of the Arabian Gulf (150–180 km), low-observable cruise missiles and One-Way Attack (OWA) loitering drones operating below ground-radar lines-of-sight represent a growing regional reality, placing iconic civilian infrastructure at severe symbolic risk.")

    # 3. Section 2
    add_section_header(doc, "2", "The Ideology & Solution: Project Murqab Al-Saqr (The Falcon’s Watchtower)")
    add_paragraph(doc, "<b>Project Murqab Al-Saqr</b> bridges two deep pillars of Arabian heritage into a single, cohesive technological doctrine:")
    add_bullet(doc, "Al-Murqab (المرقب — The Bedouin Watchtower)", "Historically, <i>Al-Murqab</i> was the fortified stone watchtower erected on high desert dunes and coastal promontories across the Emirates. It stood as an unwavering sentinel, providing early warning against maritime raids, desert incursions, and smoke on the horizon. In this system, <i>Murqab</i> represents the unshakeable ground infrastructure, the 800-meter structural waveguides, and the hermetic sanctuary that shields human life from disaster.")
    add_bullet(doc, "Al-Saqr (الصقر — The Noble Falcon)", "The falcon represents sovereign vigilance, predatory visual acuity, and undisputed mastery of the upper skies. In falconry, the bird soars above its domain, spotting micro-movements from extreme altitudes and striking with millimeter precision. In this system, <i>Saqr</i> embodies the active, high-altitude winged platforms and rapid-descent rescue shuttles that patrol the upper atmosphere and dive in to execute precision rescue missions.")

    add_paragraph(doc, "Together, <b>Murqab Al-Saqr</b> is an autonomous, externally deployed aeromechanical network forming a permanent 360° defensive and rescue ring around the tower:")
    add_ascii_diagram(doc)

    add_subsection_header(doc, "A. Civil Protection & Rapid Evacuation Corridor")
    add_bullet(doc, "Autonomous External Transit", "Operates completely decoupled from compromised internal building cores, deploying rapid climber-shuttles along tensioned pathways at 10–12 m/s.")
    add_bullet(doc, "Hermetic Air-Lock Docking", "Shuttles mechanically interface with the building’s integrated facade rails, deploying positive-pressure thermal seals that eliminate external smoke hazard and prevent the fatal internal 'chimney effect.'")
    add_bullet(doc, "Targeted Fire Suppression", "External delivery of concentrated, advanced aerosol fire-knockdown compounds directly into the origin point, preserving load-bearing structural concrete even if internal water mains fail.")

    add_subsection_header(doc, "B. Sovereign Defense & Early Warning Sentinel")
    add_bullet(doc, "Radar Horizon Multiplication", "Elevating electro-optical/infrared (EO/IR) and lightweight AESA surveillance arrays to 800–1,000 meters extends the maritime radar horizon from ~30 km to <b>over 130 km</b>, effectively monitoring low-altitude aerial avenues across the Arabian Gulf with up to 30 minutes of actionable early warning.")
    add_bullet(doc, "Elevated C-UAS & Electronic Shielding", "Continuous megawatt-class tethered power drives directional jamming, optical dazzling, and RF counter-drone measures to divert loitering threats far outside kinetic impact distance.")

    # 4. Section 3
    add_section_header(doc, "3", "Core Architectural Modules (High-Level Overview)")
    add_bullet(doc, "High-Altitude Wing-Box Gyrodynes (The Sentinels / Al-Saqr)", "High-efficiency tethered aerodynamic platforms combining box-wing passive wind lift with high-torque variable-pitch electric rotors. Delivers millisecond-level reactive cyclic authority to neutralize upper-level desert wind shears without heavy onboard batteries.")
    add_bullet(doc, "Phase-Controlled Distributed Waveguide Tethers (The Vertical Murqab)", "High-tensile aramid lines providing continuous High-Voltage Direct Current (HVDC) power and secure optical telemetry. Integrated with miniature intermediate phase-tuning nodes that break mechanical resonance and maintain vertical alignment against facade offsets.")
    add_bullet(doc, "High-Speed Autonomous Evacuation Shuttles", "Specialized climber modules capable of ascending and descending the stabilized tethers with a 190 kg operational payload (2 occupants + life-support gear per cycle).")
    add_bullet(doc, "Hexagonal Shared-Anchor Ground Network (The Base Murqab)", "A 6-sector geometric ring sharing high-torque mechatronic servo-winches, minimizing real estate intrusion and integrating into the Downtown Dubai promenade and parkscapes.")

    # 5. Section 4
    add_section_header(doc, "4", "Comprehensive Investment Breakdown (ROM Estimates)")
    add_paragraph(doc, "The following estimates provide a Turnkey Rough Order of Magnitude (ROM) budget covering all engineering, qualification, manufacturing, deployment, and testing phases for the complete 6-sector network:")
    add_table(doc)

    # 6. Section 5
    add_section_header(doc, "5", "Cost of Inaction: Comprehensive Risk & Loss Exposure")
    add_paragraph(doc, "Neglecting to establish an independent external safety and defense corridor exposes sovereign stakeholders, asset owners (<i>Emaar</i>), and the nation's economic ecosystem to unrecoverable risks:")
    add_exposure_box(doc)
    add_bullet(doc, "Catastrophic Human Casualty Exposure", "An uncontained mid-level fire or blast isolating upper residential and hotel floors exposes operators to massive international wrongful death litigation, reputational devastation, and insurance liabilities ranging from <b>$500M to $1.2B</b>.")
    add_bullet(doc, "Permanent Structural Compromise of the Asset", "High-strength reinforced concrete subjected to temperatures above 600 °C suffers irreversible micro-cracking and steel tendon relaxation. An uncontained incident risks condemning the <b>$1.8B+ architectural icon permanently</b>.")
    add_bullet(doc, "Systemic Sovereign Economic Impact", "Dubai’s global value proposition is anchored in being the world's most secure, ultra-luxurious, and technologically advanced safe haven for international capital. A single unmitigated catastrophe on the world's tallest tower, captured live by global media, would shatter investor confidence, severely impacting the prime real estate market, tourism inflows, and foreign direct investment across the UAE, with indirect economic losses estimated between <b>$10B and $25B+</b>.")

    # 7. Section 6
    add_section_header(doc, "6", "Strategic Imperative & Sovereign Vision")
    add_paragraph(doc, "At an estimated turnkey investment of <b>~$125M</b>, <b>Project Murqab Al-Saqr</b> represents <b>less than 7% of the Burj Khalifa’s replacement cost</b> and a fractional insurance premium against tens of billions in potential sovereign exposure.\n\nBy marrying the historic, protective vigilance of the Arabian watchtower (<i>Al-Murqab</i>) with the soaring aerial mastery of the desert falcon (<i>Al-Saqr</i>), the United Arab Emirates can once again lead the world: transforming the pinnacle of human architectural ambition into the world’s most resilient, self-protecting, and tactically safeguarded megastructure.")

    # Sign-off card
    sign_text = f"<b>Document Attribution &amp; Distribution Notice:</b>\nPrepared by S.Khylevych for Carlo David  |  {escape_amp(WATERMARK_TEXT)}\nClassification: Strategic Sovereign Infrastructure Proposal  |  Date: September 2026"
    sh = measure_pango(doc.cr, sign_text, CONTENT_WIDTH - 20, 'Liberation Sans 7.6') + 12

    def render_sign(cr, y):
        cr.save()
        cr.set_source_rgb(0.95, 0.96, 0.98)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, sh)
        cr.fill()
        cr.set_source_rgb(0.77, 0.61, 0.15)
        cr.set_line_width(1.0)
        cr.rectangle(MARGIN_LEFT, y, CONTENT_WIDTH, sh)
        cr.stroke()

        layout = PangoCairo.create_layout(cr)
        layout.set_width(int((CONTENT_WIDTH - 20) * Pango.SCALE))
        layout.set_font_description(Pango.FontDescription('Liberation Sans 7.4'))
        layout.set_markup(sign_text)
        cr.set_source_rgb(0.20, 0.25, 0.35)
        cr.move_to(MARGIN_LEFT + 10, y + 6)
        PangoCairo.show_layout(cr, layout)
        cr.restore()

    doc.add_op(render_sign, sh + 4)

    doc.finalize()

def apply_pdf_security(raw_pdf, secured_pdf):
    cmd = [
        "gs", "-q", "-dNOPAUSE", "-dBATCH", "-sDEVICE=pdfwrite",
        "-sOwnerPassword=MurqabAlSaqr_SecureOwner_2026!",
        "-dEncryptionR=3",
        "-dKeyLength=128",
        "-dPermissions=-3900",
        f"-sOutputFile={secured_pdf}",
        raw_pdf
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Ghostscript failed: {res.stderr}")

if __name__ == "__main__":
    raw_pdf = "/home/hills/Documents/fallaut/raw_murqab_al_saqr.pdf"
    secured_pdf = "/home/hills/Documents/fallaut/Project_Murqab_Al-Saqr_Executive_Summary.pdf"

    print("Building raw PDF with Cairo and Pango...")
    build_pdf(raw_pdf)
    print("Applying 128-bit encryption and permission restrictions...")
    apply_pdf_security(raw_pdf, secured_pdf)
    if os.path.exists(raw_pdf):
        os.remove(raw_pdf)
    print(f"Successfully generated secured PDF: {secured_pdf}")
