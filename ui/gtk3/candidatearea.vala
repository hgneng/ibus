/* vim:set et sts=4 sw=4:
 *
 * ibus - The Input Bus
 *
 * Copyright(c) 2011-2015 Peng Huang <shawn.p.huang@gmail.com>
 * Copyright(c) 2015 Takao Fujiwara <takao.fujiwara1@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
 * USA
 */

extern int ibs_word_begin;
extern int ibs_word_end;
extern int ibs_char_limit;
extern char* ibs_words[];
extern void ibs_speak_politely(char *text);
extern void ibs_stop();

class CandidateArea : Gtk.Box {
    private bool m_vertical;
    private Gtk.Label[] m_labels;
    private Gtk.Label[] m_candidates;
    private Gtk.Widget[] m_widgets;

    private IBus.Text[] m_ibus_candidates;
    private uint m_focus_candidate;
    private bool m_show_cursor;

    private const string LABELS[] = {
        "1.", "2.", "3.", "4.", "5.", "6.", "7.", "8.",
        "9.", "0.", "a.", "b.", "c.", "d.", "e.", "f."
    };

    private const string PREV_PAGE_ICONS[] = {
        "go-previous",
        "go-up"
    };

    private const string NEXT_PAGE_ICONS[] = {
        "go-next",
        "go-down"
    };

    public signal void candidate_clicked(uint index, uint button, uint state);
    public signal void page_up();
    public signal void page_down();
    public signal void cursor_up();
    public signal void cursor_down();

    public CandidateArea(bool vertical) {
        GLib.Object();
        set_vertical(vertical, true);
    }

    public bool get_vertical() {
        return m_vertical;
    }

    public void set_vertical(bool vertical, bool force = false) {
        if (!force && m_vertical == vertical)
            return;
        m_vertical = vertical;
        orientation = vertical ?
            Gtk.Orientation.VERTICAL :
            Gtk.Orientation.HORIZONTAL;
        recreate_ui();

        if (m_ibus_candidates.length > 0) {
            // Workaround a vala issue
            // https://bugzilla.gnome.org/show_bug.cgi?id=661130
            set_candidates((owned)m_ibus_candidates,
                           m_focus_candidate,
                           m_show_cursor);
            show_all();
        }
    }

    public void set_labels(IBus.Text[] labels) {
        int i;
        for (i = 0; i < int.min(16, labels.length); i++)
            m_labels[i].set_text(labels[i].get_text());
        for (; i < 16; i++)
            m_labels[i].set_text(LABELS[i]);
    }

    public bool read_candidate(uint pos, IBus.Text text, bool read_word_character = true) {
      string str = text.get_text();
      if (!read_word_character && text.get_length() > 1) {
        if (pos > 0)
          ibs_speak_politely(pos.to_string() + str);
        else
          ibs_speak_politely(str);
      } else {
        int i = 0;
        unichar c = 0;
        string speech = "";
        if (pos > 0)
          speech += pos.to_string();

        bool confuse = false;
        while (str.get_next_char(ref i, out c)) {
          int code = (int)c;
          string word = (string)ibs_words[code - ibs_word_begin];
          if (code >= ibs_word_begin && code <= ibs_word_end && ibs_words[code - ibs_word_begin] != null)
            speech += word;
          else
            speech += c.to_string();
        
          if (i > 1 && word.index_of_char((unichar)30340) != word.last_index_of_char((unichar)30340))
            confuse = true;
        }
        
        ibs_speak_politely(speech);
        
        if (i > 3 || confuse)
          return true; // confuse next word
      }

      return false; // not confuse next word
    }

    public void set_candidates(IBus.Text[] candidates,
                               uint focus_candidate = 0,
                               bool show_cursor = true) {
        debug("[hgneng] enter set_candidates: %u/%d", focus_candidate, candidates.length);
        ibs_stop();
        if (focus_candidate > 0) {
          // read current candidate
          read_candidate(0, candidates[focus_candidate]);
        } else {
          // read candidate list
          bool confuse = false;
          for (int i = 0; i < candidates.length; i++) {
            bool read_character = true;
            if (candidates[i].get_length() > ibs_char_limit)
              read_character = false;

            if (i > 0 && confuse)
              confuse = read_candidate(i + 1, candidates[i], read_character);
            else
              confuse = read_candidate(0, candidates[i], read_character);
          }
        }

        m_ibus_candidates = candidates;
        m_focus_candidate = focus_candidate;
        m_show_cursor = show_cursor;

        assert(candidates.length < 16);
        for (int i = 0 ; i < 16 ; i++) {
            Gtk.Label label = m_candidates[i];
            bool visible = false;
            if (i < candidates.length) {
                Pango.AttrList attrs = get_pango_attr_list_from_ibus_text(candidates[i]);
                if (i == focus_candidate && show_cursor) {
                    Gtk.StyleContext context = m_candidates[i].get_style_context();
                    Gdk.RGBA color = context.get_color(Gtk.StateFlags.SELECTED);
                    Pango.Attribute pango_attr = Pango.attr_foreground_new(
                            (uint16)(color.red * uint16.MAX),
                            (uint16)(color.green * uint16.MAX),
                            (uint16)(color.blue * uint16.MAX));
                    pango_attr.start_index = 0;
                    pango_attr.end_index = candidates[i].get_text().length;
                    attrs.insert((owned)pango_attr);

                    color = context.get_background_color(Gtk.StateFlags.SELECTED);
                    pango_attr = Pango.attr_background_new(
                            (uint16)(color.red * uint16.MAX),
                            (uint16)(color.green * uint16.MAX),
                            (uint16)(color.blue * uint16.MAX));
                    pango_attr.start_index = 0;
                    pango_attr.end_index = candidates[i].get_text().length;
                    attrs.insert((owned)pango_attr);
                }
                label.set_text(candidates[i].get_text());
                label.set_attributes(attrs);
                visible = true;
            } else {
                label.set_text("");
                label.set_attributes(new Pango.AttrList());
            }
            if (m_vertical) {
                m_widgets[i * 2].set_visible(visible);
                m_widgets[i * 2 +1].set_visible(visible);
            } else {
                m_widgets[i].set_visible(visible);
            }
        }
    }

    private void recreate_ui() {
        foreach (Gtk.Widget w in get_children()) {
            w.destroy();
        }

        Gtk.Button prev_button = new Gtk.Button();
        prev_button.clicked.connect((b) => page_up());
        prev_button.set_image(new Gtk.Image.from_icon_name(
                                  PREV_PAGE_ICONS[orientation],
                                  Gtk.IconSize.MENU));
        prev_button.set_relief(Gtk.ReliefStyle.NONE);

        Gtk.Button next_button = new Gtk.Button();
        next_button.clicked.connect((b) => page_down());
        next_button.set_image(new Gtk.Image.from_icon_name(
                                  NEXT_PAGE_ICONS[orientation],
                                  Gtk.IconSize.MENU));
        next_button.set_relief(Gtk.ReliefStyle.NONE);

        if (m_vertical) {
            // Add Candidates
            Gtk.Box candidates_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            pack_start(candidates_hbox, false, false, 0);
            Gtk.Box labels_vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            labels_vbox.set_homogeneous(true);
            Gtk.Box candidates_vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            candidates_vbox.set_homogeneous(true);
            candidates_hbox.pack_start(labels_vbox, false, false, 4);
            candidates_hbox.pack_start(new VSeparator(), false, false, 0);
            candidates_hbox.pack_start(candidates_vbox, true, true, 4);

            // Add HSeparator
            pack_start(new HSeparator(), false, false, 0);

            // Add buttons
            Gtk.Box buttons_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            Gtk.Label state_label = new Gtk.Label(null);
            state_label.set_size_request(20, -1);
            buttons_hbox.pack_start(state_label, true, true, 0);
            buttons_hbox.pack_start(prev_button, false, false, 0);
            buttons_hbox.pack_start(next_button, false, false, 0);
            pack_start(buttons_hbox, false, false, 0);

            m_labels = {};
            m_candidates = {};
            m_widgets = {};
            for (int i = 0; i < 16; i++) {
                Gtk.Label label = new Gtk.Label(LABELS[i]);
                label.set_halign(Gtk.Align.START);
                label.set_valign(Gtk.Align.CENTER);
                label.show();
                m_labels += label;

                Gtk.Label candidate = new Gtk.Label("test");
                candidate.set_halign(Gtk.Align.START);
                candidate.set_valign(Gtk.Align.CENTER);
                candidate.show();
                m_candidates += candidate;

                /* Use Gtk.Widget.set_margin_start() since gtk 3.12 */
                label.set_padding(8, 0);
                candidate.set_padding(8, 0);

                // Make a copy of i to workaround a bug in vala.
                // https://bugzilla.gnome.org/show_bug.cgi?id=628336
                int index = i;
                Gtk.EventBox label_ebox = new Gtk.EventBox();
                label_ebox.set_no_show_all(true);
                label_ebox.button_press_event.connect((w, e) => {
                    candidate_clicked(i, e.button, e.state);
                    return true;
                });
                label_ebox.add(label);
                labels_vbox.pack_start(label_ebox, false, false, 2);
                m_widgets += label_ebox;

                Gtk.EventBox candidate_ebox = new Gtk.EventBox();
                candidate_ebox.set_no_show_all(true);
                candidate_ebox.button_press_event.connect((w, e) => {
                    candidate_clicked(index, e.button, e.state);
                    return true;
                });
                candidate_ebox.add(candidate);
                candidates_vbox.pack_start(candidate_ebox, false, false, 2);
                m_widgets += candidate_ebox;
            }
        } else {
            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            add(hbox);

            m_labels = {};
            m_candidates = {};
            m_widgets = {};
            for (int i = 0; i < 16; i++) {
                Gtk.Label label = new Gtk.Label(LABELS[i]);
                label.set_halign(Gtk.Align.START);
                label.set_valign(Gtk.Align.CENTER);
                label.show();
                m_labels += label;

                Gtk.Label candidate = new Gtk.Label("test");
                candidate.set_halign(Gtk.Align.START);
                candidate.set_valign(Gtk.Align.CENTER);
                candidate.show();
                m_candidates += candidate;

                Gtk.Box candidate_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                candidate_hbox.show();
                candidate_hbox.pack_start(label, false, false, 2);
                candidate_hbox.pack_start(candidate, false, false, 2);

                // Make a copy of i to workaround a bug in vala.
                // https://bugzilla.gnome.org/show_bug.cgi?id=628336
                int index = i;
                Gtk.EventBox ebox = new Gtk.EventBox();
                ebox.set_no_show_all(true);
                ebox.button_press_event.connect((w, e) => {
                    candidate_clicked(index, e.button, e.state);
                    return true;
                });
                ebox.add(candidate_hbox);
                hbox.pack_start(ebox, false, false, 4);
                m_widgets += ebox;
            }
            hbox.pack_start(new VSeparator(), false, false, 0);
            hbox.pack_start(prev_button, false, false, 0);
            hbox.pack_start(next_button, false, false, 0);
        }
    }
}

