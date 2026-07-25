import type { Question } from '@/types/database.types';

export const SAMPLE_QUESTIONS: Question[] = [
  {
    id: 'q-001',
    question_code: 'KM-001',
    type: 'kariamen',
    is_premium: false,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'When a police officer stands at an intersection with both arms extended horizontally to the sides, all vehicles from every direction must stop.',
    question_text_ja:
      '警察官が交差点で両腕を横（水平）に伸ばして立っているとき、すべての方向の車は停止しなければならない。',
    question_text_id:
      'Ketika polisi berdiri di persimpangan dengan kedua tangan terentang ke samping (horizontal), semua kendaraan dari segala arah harus berhenti.',
    explanation_en:
      'Correct. A police officer with arms extended horizontally signals a full red light for ALL directions. No direction is permitted to proceed. This overrides any traffic signal currently showing.',
    explanation_ja:
      '正解。警察官の両腕水平は全方向停止を意味します。交通信号よりも警察官の手信号が優先されます。',
    explanation_id:
      'Benar. Tangan horizontal = semua arah berhenti, setara lampu merah penuh. Isyarat polisi selalu mengalahkan lampu lalu lintas.',
    explanation_zh:
      '正确。警察双臂水平伸展表示所有方向停车,无论交通信号灯显示什么,都必须服从警察的手势信号。',
    explanation_vi:
      'Đúng. Cảnh sát giang tay ngang có nghĩa là tất cả các hướng phải dừng lại - tín hiệu của cảnh sát luôn ưu tiên hơn đèn giao thông.',
    explanation_ko:
      '정답. 경찰관이 양팔을 수평으로 뻗으면 모든 방향 정지 신호입니다. 신호등보다 경찰관 수신호가 우선합니다.',
    explanation_tl:
      'Tama. Ang pulis na nakabukas ang mga braso nang pahalang ay nangangahulugang hinto para sa lahat ng direksyon, mas mahalaga ito kaysa sa traffic lights.',
    explanation_pt:
      'Correto. Policial com bracos estendidos horizontalmente significa parada total em todas as direcoes - o sinal do policial tem prioridade sobre o semaforo.',
    explanation_ne:
      'सही छ। प्रहरीले दुवै हात तेर्सो फैलाएको अवस्थामा सबै दिशाबाट गाडी रोक्नुपर्छ, ट्राफिक लाइटभन्दा प्रहरीको संकेत प्राथमिकतामा हुन्छ।',
  },
  {
    id: 'q-002',
    question_code: 'KM-002',
    type: 'kariamen',
    is_premium: false,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'On a public road with no posted speed limit sign, the maximum speed for a regular passenger vehicle is 60 km/h.',
    question_text_ja:
      '速度制限の標識がない一般道路では、普通自動車の最高速度は時速60キロメートルである。',
    question_text_id:
      'Di jalan umum tanpa rambu batas kecepatan, kecepatan maksimum kendaraan penumpang biasa adalah 60 km/jam.',
    explanation_en:
      'Correct. This is the statutory speed - 60 km/h on public roads without a posted limit. Do not confuse with expressways (100 km/h default). The question specifies a regular public road.',
    explanation_ja:
      '正解。これは法定速度です。標識のない一般道路での最高速度は時速60km。高速道路（100km/h）と混同しないでください。',
    explanation_id:
      'Benar. Ini disebut kecepatan undang-undang (hoteisokudo). Tanpa rambu di jalan biasa = maksimum 60 km/jam. Jangan keliru dengan jalan tol (100 km/jam).',
    explanation_zh:
      '正确。这是法定速度,无限速标志的普通公路最高时速60公里。不要与高速公路(100公里/小时)混淆。',
    explanation_vi:
      'Đúng. Đây là tốc độ pháp định - 60 km/h trên đường công cộng không có biển giới hạn tốc độ. Không nhầm với đường cao tốc (100 km/h).',
    explanation_ko:
      '정답. 이것은 법정속도입니다. 속도 표지판이 없는 일반 도로에서 최고속도는 60km/h. 고속도로(100km/h)와 혼동하지 마세요.',
    explanation_tl:
      'Tama. Ito ang statutory speed - 60 km/h sa pampublikong daan na walang speed limit sign. Huwag paghalo sa expressway (100 km/h).',
    explanation_pt:
      'Correto. Esta e a velocidade legal - 60 km/h em vias publicas sem placa de limite. Nao confunda com rodovias (100 km/h).',
    explanation_ne:
      'सही छ। यो कानूनी गति हो, गति सीमाको साइन नभएको सार्वजनिक सडकमा अधिकतम ६० किमी/घण्टा। एक्सप्रेसवे (१०० किमी/घण्टा) सँग भ्रमित नगर्नुहोस्।',
  },
  {
    id: 'q-003',
    question_code: 'KM-003',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      'A 50 km/h speed limit sign posted on the roadside applies to all types of motor vehicles passing through that road, including large motorcycles.',
    question_text_ja:
      '道路脇に設置された時速50キロの速度制限標識は、大型自動二輪車を含む、その道路を通行するすべての種類の自動車に適用される。',
    question_text_id:
      'Rambu batas kecepatan 50 km/jam yang dipasang di tepi jalan berlaku untuk semua jenis kendaraan bermotor yang melintas di jalan tersebut, termasuk sepeda motor besar.',
    explanation_en:
      'SUBTLE TRAP: Large motorcycles follow the posted sign. But mopeds (under 50cc) are still capped at 30 km/h even when the sign shows 50. Read carefully which vehicle type the question refers to.',
    explanation_ja:
      'ひっかけ問題：大型自動二輪車は標識に従います。しかし原動機付自転車（50cc未満）は標識が50でも最高速度30km/hのままです。問題文がどの車両種別を指しているか注意して読みましょう。',
    explanation_id:
      'JEBAKAN HALUS: Motor besar mengikuti rambu. Tapi moped (di bawah 50cc) tetap punya batas maksimum 30 km/jam meskipun rambu menunjukkan 50. Baca baik-baik jenis kendaraan yang disebutkan pada soal.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-004',
    question_code: 'KM-004',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      "A police officer is standing at an intersection with one arm pointing straight up (vertical). The traffic light is green. The driver must still follow the police officer's signal and stop.",
    question_text_ja:
      '警察官が交差点で片腕を垂直に上げて立っている。信号は青（緑）を示している。運転者はそれでも警察官の合図に従い、停止しなければならない。',
    question_text_id:
      'Seorang polisi berdiri di persimpangan dengan satu tangan menunjuk ke atas (vertikal). Lampu lalu lintas menunjukkan hijau. Pengemudi tetap harus mengikuti isyarat polisi dan berhenti.',
    explanation_en:
      "Correct. A police officer's signal always overrides the traffic light. An arm pointing straight up is equivalent to a yellow signal. Priority order: police signal, traffic light, road sign, road markings.",
    explanation_ja:
      '正解。警察官の合図は常に信号よりも優先されます。腕を垂直に上げるのは黄色信号に相当します。優先順位：警察官の合図＞信号＞標識＞道路標示。',
    explanation_id:
      'Benar. Isyarat polisi selalu mengalahkan lampu lalu lintas. Tangan polisi menunjuk vertikal ke atas setara sinyal kuning. Urutan prioritas: isyarat polisi, sinyal lalu lintas, rambu, marka jalan.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-005',
    question_code: 'KM-005',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      "When about to overtake a bicycle traveling along the edge of the road, a car driver may overtake from the bicycle's left side to avoid disrupting oncoming traffic.",
    question_text_ja:
      '路肩を走行している自転車を追い越す際、対向車の流れを妨げないよう、自転車の左側から追い越してもよい。',
    question_text_id:
      'Saat akan mendahului sebuah sepeda yang sedang melaju di tepi jalan, pengemudi mobil boleh mendahului dari sisi kiri sepeda tersebut agar tidak mengganggu arus lalu lintas dari arah berlawanan.',
    explanation_en:
      'Incorrect. In Japan, motor vehicles must overtake from the RIGHT side. Overtaking from the left is prohibited except in very specific circumstances.',
    explanation_ja:
      '誤り。日本では自動車は右側から追い越さなければなりません。左側からの追い越しは、非常に限られた特定の状況を除き禁止されています。',
    explanation_id:
      'Salah. Di Jepang, kendaraan bermotor wajib mendahului dari sisi KANAN. Mendahului dari kiri dilarang kecuali kondisi tertentu yang sangat spesifik.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-006',
    question_code: 'KM-006',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'In an area with a no-horn sign, drivers may still sound the horn if necessary to prevent an accident that is about to happen.',
    question_text_ja:
      '警笛禁止の標識がある区域でも、まさに起ころうとしている事故を防ぐために必要な場合は、運転者は警笛を鳴らしてもよい。',
    question_text_id:
      'Di area dengan rambu larangan klakson, pengemudi tetap boleh membunyikan klakson apabila diperlukan untuk mencegah kecelakaan yang akan terjadi secara langsung.',
    explanation_en:
      'Correct. Even where a no-horn sign is posted, using the horn is still permitted in emergencies to avoid a life-threatening accident.',
    explanation_ja:
      '正解。警笛禁止の標識があっても、命に関わる事故を避けるための緊急時にはクラクションの使用が認められています。',
    explanation_id:
      'Benar. Meskipun ada rambu dilarang klakson, penggunaan klakson tetap diperbolehkan dalam situasi darurat untuk menghindari kecelakaan yang mengancam nyawa.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-007',
    question_code: 'KM-007',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      'When about to overtake a vehicle near a pedestrian crossing, a driver may overtake as long as no pedestrian is currently crossing.',
    question_text_ja:
      '横断歩道付近で車両を追い越そうとする場合、その時点で歩行者が横断していなければ追い越してもよい。',
    question_text_id:
      'Ketika hendak mendahului kendaraan di dekat zebra cross, pengemudi boleh mendahului asalkan tidak ada pejalan kaki yang sedang menyeberang saat itu.',
    explanation_en:
      'Incorrect. Overtaking a vehicle near a pedestrian crossing is strictly prohibited, regardless of whether a pedestrian is crossing at that moment.',
    explanation_ja:
      '誤り。横断歩道付近での追い越しは、その時歩行者が横断しているかどうかにかかわらず、固く禁止されています。',
    explanation_id:
      'Salah. Mendahului kendaraan di sekitar zebra cross dilarang keras, terlepas ada atau tidaknya pejalan kaki yang menyeberang saat itu.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-008',
    question_code: 'KM-008',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'A vehicle that has just been in an accident and stopped suddenly inside a tunnel must immediately turn on its hazard lights and place a warning triangle behind the vehicle.',
    question_text_ja:
      'トンネル内で事故に遭い急停止した車両は、直ちにハザードランプを点灯し、車両の後方に停止表示器材を設置しなければならない。',
    question_text_id:
      'Kendaraan yang baru saja mengalami kecelakaan dan berhenti mendadak di dalam terowongan wajib segera menyalakan lampu hazard dan menempatkan segitiga pengaman di belakang kendaraan.',
    explanation_en:
      'Correct. Inside a tunnel, a stopped vehicle must turn on its hazard lights and set up a warning triangle. This requirement applies in tunnels and on expressways.',
    explanation_ja:
      '正解。トンネル内で停止した車両はハザードランプを点灯し、停止表示器材を設置する義務があります。この義務はトンネル内と高速道路で適用されます。',
    explanation_id:
      'Benar. Di dalam terowongan, kendaraan yang berhenti wajib menyalakan hazard dan memasang segitiga pengaman. Kewajiban ini berlaku di terowongan dan jalan tol.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-009',
    question_code: 'KM-009',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      'A driver who sees a STOP sign must come to a complete stop exactly at the stop line, but if there is no stop line, the driver only needs to slow down to a low speed before entering the intersection.',
    question_text_ja:
      '「止まれ」の標識を見た運転者は停止線の直前で完全に停止しなければならないが、停止線がない場合は交差点に入る前に低速まで減速するだけでよい。',
    question_text_id:
      'Pengemudi yang melihat rambu STOP wajib berhenti sepenuhnya tepat di garis berhenti, namun jika tidak ada garis berhenti, pengemudi cukup memperlambat kendaraan hingga kecepatan rendah sebelum memasuki persimpangan.',
    explanation_en:
      'Incorrect. If there is a STOP sign but no stop line, the driver must still come to a complete stop, not merely slow down.',
    explanation_ja:
      '誤り。「止まれ」の標識があっても停止線がない場合でも、運転者は減速するだけでなく完全に停止しなければなりません。',
    explanation_id:
      'Salah. Jika ada rambu STOP tapi tidak ada garis berhenti, pengemudi tetap wajib berhenti sepenuhnya, bukan sekadar memperlambat.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-010',
    question_code: 'KM-010',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'A vehicle traveling on a priority road does not need to give way to a vehicle emerging from a minor road, even if that vehicle already reached the intersection first.',
    question_text_ja:
      '優先道路を走行している車両は、他の車両が先に交差点に到達していたとしても、小さい道路から出てくる車両に道を譲る必要はない。',
    question_text_id:
      'Kendaraan yang sedang berjalan di jalan utama tidak perlu memberikan prioritas kepada kendaraan yang keluar dari jalan kecil, meskipun kendaraan tersebut sudah berada di persimpangan lebih dahulu.',
    explanation_en:
      'Correct. A vehicle on a priority road has a higher right of way than a vehicle entering from a minor road, regardless of who arrived at the intersection first.',
    explanation_ja:
      '正解。優先道路上の車両は、どちらが先に交差点に到達したかに関わらず、小さな道路から進入する車両よりも優先的な通行権を持ちます。',
    explanation_id:
      'Benar. Kendaraan di jalan prioritas memiliki hak lewat lebih tinggi dari kendaraan yang masuk dari jalan kecil, terlepas dari siapa yang lebih dulu tiba di persimpangan.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
];
