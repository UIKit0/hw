/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */


package org.hedgewars.hedgeroid;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.Team;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnFocusChangeListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ScrollView;
import android.widget.SimpleAdapter;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

public class TeamCreatorActivity extends Activity implements Runnable{

	private TextView name;
	private Spinner difficulty, grave, flag, voice, fort;
	private ImageView imgFort;
	private ArrayList<ImageButton> hogDice = new ArrayList<ImageButton>();
	private ArrayList<Spinner> hogHat = new ArrayList<Spinner>();
	private ArrayList<EditText> hogName = new ArrayList<EditText>();
	private ImageButton back, save, voiceButton;
	private ScrollView scroller;
	private MediaPlayer mp = null;
	private boolean settingsChanged = false;
	private boolean saved = false;
	private String fileName = null;

	private List<HashMap<String, ?>> flagsData, typesData, gravesData, hatsData;
	private List<String> voicesData, fortsData;

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.team_creation);

		name = (TextView) findViewById(R.id.txtName);
		difficulty = (Spinner) findViewById(R.id.spinType);
		grave = (Spinner) findViewById(R.id.spinGrave);
		flag = (Spinner) findViewById(R.id.spinFlag);
		voice = (Spinner) findViewById(R.id.spinVoice);
		fort = (Spinner) findViewById(R.id.spinFort);

		imgFort = (ImageView) findViewById(R.id.imgFort);

		back = (ImageButton) findViewById(R.id.btnBack);
		save = (ImageButton) findViewById(R.id.btnSave);
		voiceButton = (ImageButton) findViewById(R.id.btnPlay);

		scroller = (ScrollView) findViewById(R.id.scroller);

		save.setOnClickListener(saveClicker);
		back.setOnClickListener(backClicker);

		LinearLayout ll = (LinearLayout) findViewById(R.id.HogsContainer);
		for (int i = 0; i < ll.getChildCount(); i++) {
			RelativeLayout team_creation_entry = (RelativeLayout) ll.getChildAt(i);

			hogHat.add((Spinner) team_creation_entry
					.findViewById(R.id.spinTeam1));
			hogDice.add((ImageButton) team_creation_entry
					.findViewById(R.id.btnTeam1));
			hogName.add((EditText) team_creation_entry
					.findViewById(R.id.txtTeam1));
		}

		gravesData = new ArrayList<HashMap<String, ?>>();
		SimpleAdapter sa = new SimpleAdapter(this, gravesData,
				R.layout.spinner_textimg_entry, new String[] { "txt", "img" },
				new int[] { R.id.spinner_txt, R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		sa.setViewBinder(viewBinder);
		grave.setAdapter(sa);
		grave.setOnFocusChangeListener(focusser);

		flagsData = new ArrayList<HashMap<String, ?>>();
		sa = new SimpleAdapter(this, flagsData, R.layout.spinner_textimg_entry,
				new String[] { "txt", "img" }, new int[] { R.id.spinner_txt,
				R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		sa.setViewBinder(viewBinder);
		flag.setAdapter(sa);
		flag.setOnFocusChangeListener(focusser);

		typesData = new ArrayList<HashMap<String, ?>>();
		sa = new SimpleAdapter(this, typesData, R.layout.spinner_textimg_entry,
				new String[] { "txt", "img" }, new int[] { R.id.spinner_txt,
				R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		difficulty.setAdapter(sa);
		difficulty.setOnFocusChangeListener(focusser);

		hatsData = new ArrayList<HashMap<String, ?>>();
		sa = new SimpleAdapter(this, hatsData, R.layout.spinner_textimg_entry,
				new String[] { "txt", "img" }, new int[] { R.id.spinner_txt,
				R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		sa.setViewBinder(viewBinder);
		for (Spinner spin : hogHat) {
			spin.setAdapter(sa);
		}

		voicesData = new ArrayList<String>();
		ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, R.layout.listview_item, voicesData);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		voice.setAdapter(adapter);
		voice.setOnFocusChangeListener(focusser);
		voiceButton.setOnClickListener(voiceClicker);

		fortsData = new ArrayList<String>();
		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, fortsData);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		fort.setAdapter(adapter);
		fort.setOnItemSelectedListener(fortSelector);
		fort.setOnFocusChangeListener(focusser);

		new Thread(this).start();
	}

	public void run(){
		ArrayList<HashMap<String, ?>> gravesData = FrontendDataUtils.getGraves(this);
		ArrayList<HashMap<String, ?>> flagsData = FrontendDataUtils.getFlags(this);
		ArrayList<HashMap<String, ?>> typesData = FrontendDataUtils.getTypes(this);
		ArrayList<HashMap<String, ?>> hatsData = FrontendDataUtils.getHats(this);
		ArrayList<String> voicesData = FrontendDataUtils.getVoices(this);
		ArrayList<String> fortsData = FrontendDataUtils.getForts(this);
		
		copy(this.gravesData, gravesData);
		copy(this.flagsData, flagsData);
		copy(this.typesData, typesData);
		copy(this.hatsData, hatsData);
		copy(this.voicesData, voicesData);
		copy(this.fortsData, fortsData);
		
		this.runOnUiThread(new Runnable(){
			public void run() {
				((SimpleAdapter)grave.getAdapter()).notifyDataSetChanged();
				((SimpleAdapter)flag.getAdapter()).notifyDataSetChanged();
				((SimpleAdapter)difficulty.getAdapter()).notifyDataSetChanged();
				((SimpleAdapter)hogHat.get(0).getAdapter()).notifyDataSetChanged();				
				((ArrayAdapter<String>)fort.getAdapter()).notifyDataSetChanged();
				((ArrayAdapter<String>)voice.getAdapter()).notifyDataSetChanged();
			}
		});		

	}
	
	private static <T> void copy(List<T> dest, List<T> src){
		for(T t: src) dest.add(t);
	}

	public void onDestroy() {
		super.onDestroy();
		if (mp != null) {
			mp.release();
			mp = null;
		}
	}

	private OnFocusChangeListener focusser = new OnFocusChangeListener() {
		public void onFocusChange(View v, boolean hasFocus) {
			settingsChanged = true;
		}

	};

	public void onBackPressed() {
		onFinishing();
		super.onBackPressed();

	}

	private OnClickListener backClicker = new OnClickListener() {
		public void onClick(View v) {
			onFinishing();
			finish();
		}
	};

	private void onFinishing() {
		if (settingsChanged) {
			setResult(RESULT_OK);
		} else {
			setResult(RESULT_CANCELED);
		}
	}

	private OnClickListener saveClicker = new OnClickListener() {
		public void onClick(View v) {
			Toast.makeText(TeamCreatorActivity.this, R.string.saved, Toast.LENGTH_SHORT).show();
			saved = true;
			Team team = new Team();
			team.name = name.getText().toString();
			HashMap<String, Object> hashmap = (HashMap<String, Object>) flag.getSelectedItem();

			team.flag = (String) hashmap.get("txt");
			team.fort = fort.getSelectedItem().toString();
			hashmap = (HashMap<String, Object>) grave.getSelectedItem();
			team.grave = hashmap.get("txt").toString();
			team.hash = "0";
			team.voice = voice.getSelectedItem().toString();
			team.file = fileName;

			hashmap = ((HashMap<String, Object>) difficulty.getSelectedItem());
			String levelString = hashmap.get("txt").toString();
			int levelInt;
			if (levelString.equals(getString(R.string.human))) {
				levelInt = 0;
			} else if (levelString.equals(getString(R.string.bot5))) {
				levelInt = 1;
			} else if (levelString.equals(getString(R.string.bot4))) {
				levelInt = 2;
			} else if (levelString.equals(getString(R.string.bot3))) {
				levelInt = 3;
			} else if (levelString.equals(getString(R.string.bot2))) {
				levelInt = 4;
			} else {
				levelInt = 5;
			}

			for (int i = 0; i < hogName.size(); i++) {
				team.hogNames[i] = hogName.get(i).getText().toString();
				hashmap = (HashMap<String, Object>) hogHat.get(i).getSelectedItem();
				team.hats[i] = hashmap.get("txt").toString();
				team.levels[i] = levelInt;
			}
			try {
				File teamsDir = new File(getFilesDir().getAbsolutePath() + '/' + Team.DIRECTORY_TEAMS);
				if (!teamsDir.exists()) teamsDir.mkdir();
				if(team.file == null){
					team.setFileName(TeamCreatorActivity.this);
				}
				FileOutputStream fos = new FileOutputStream(String.format("%s/%s", teamsDir.getAbsolutePath(), team.file));
				team.writeToXml(fos);
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		}

	};

	private OnItemSelectedListener fortSelector = new OnItemSelectedListener() {
		@SuppressWarnings("unchecked")
		public void onItemSelected(AdapterView<?> arg0, View arg1,
				int position, long arg3) {
			settingsChanged = true;
			String fortName = (String) arg0.getAdapter().getItem(position);
			Drawable fortIconDrawable = Drawable.createFromPath(Utils
					.getDataPath(TeamCreatorActivity.this)
					+ "Forts/"
					+ fortName + "L.png");
			imgFort.setImageDrawable(fortIconDrawable);
			scroller.fullScroll(ScrollView.FOCUS_DOWN);// Scroll the scrollview
			// to the bottom, work
			// around for scollview
			// invalidation (scrolls
			// back to top)
		}

		public void onNothingSelected(AdapterView<?> arg0) {
		}

	};

	private OnClickListener voiceClicker = new OnClickListener() {
		public void onClick(View v) {
			try {
				File dir = new File(String.format("%sSounds/voices/%s",
						Utils.getDataPath(TeamCreatorActivity.this),
						voice.getSelectedItem()));
				String file = "";
				File[] dirs = dir.listFiles();
				File f = dirs[(int) Math.round(Math.random() * dirs.length)];
				if (f.getName().endsWith(".ogg"))
					file = f.getAbsolutePath();

				if (mp == null)
					mp = new MediaPlayer();
				else
					mp.reset();
				mp.setDataSource(file);
				mp.prepare();
				mp.start();
			} catch (IllegalArgumentException e) {
				e.printStackTrace();
			} catch (IllegalStateException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	};

	private void setTeamValues(Team t){

		if (t != null) {
			name.setText(t.name);
			int position = ((ArrayAdapter<String>) voice.getAdapter()).getPosition(t.voice);
			voice.setSelection(position);

			position = ((ArrayAdapter<String>) fort.getAdapter()).getPosition(t.fort);
			fort.setSelection(position);

			position = 0;
			for (HashMap<String, ?> hashmap : typesData) {
				if (hashmap.get("txt").equals(t.levels[0])) {
					difficulty.setSelection(position);
					break;
				}
			}

			position = 0;
			for (HashMap<String, ?> hashmap : gravesData) {
				if (hashmap.get("txt").equals(t.grave)) {
					grave.setSelection(position);
					break;
				}
			}

			position = 0;
			for (HashMap<String, ?> hashmap : typesData) {
				if (hashmap.get("txt").equals(t.flag)) {
					flag.setSelection(position);
					break;
				}
			}

			for (int i = 0; i < Team.maxNumberOfHogs; i++) {
				position = 0;
				for (HashMap<String, ?> hashmap : hatsData) {
					if (hashmap.get("txt").equals(t.hats[i])) {
						hogHat.get(i).setSelection(position);
					}
				}

				hogName.get(i).setText(t.hogNames[i]);
			}
			this.fileName = t.file;
		}
	}


	private SimpleAdapter.ViewBinder viewBinder = new SimpleAdapter.ViewBinder() {

		public boolean setViewValue(View view, Object data,
				String textRepresentation) {
			if (view instanceof ImageView && data instanceof Bitmap) {
				ImageView v = (ImageView) view;
				v.setImageBitmap((Bitmap) data);
				return true;
			} else {
				return false;
			}
		}
	};

}