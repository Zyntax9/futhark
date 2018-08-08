// Libraries below are imported in SequentialCSharp.hs
// using System;
// using static System.Convert;
// using static System.Math;

// Scalar functions.
static sbyte signed(byte x){ return (sbyte) x;}
static short signed(ushort x){ return (short) x;}
static int signed(uint x){ return (int) x;}
static long signed(ulong x){ return (long) x;}

static byte unsigned(sbyte x){ return (byte) x;}
static ushort unsigned(short x){ return (ushort) x;}
static uint unsigned(int x){ return (uint) x;}
static ulong unsigned(long x){ return (ulong) x;}

static sbyte add8(sbyte x, sbyte y){ return (sbyte) ((byte) x + (byte) y);}
static short add16(short x, short y){ return (short) ((ushort) x + (ushort) y);}
static int add32(int x, int y){ return (int) ((uint) x + (uint) y);}
static long add64(long x, long y){ return (long) ((ulong) x + (ulong) y);}

static sbyte sub8(sbyte x, sbyte y){ return (sbyte) ((byte) x - (byte) y);}
static short sub16(short x, short y){ return (short) ((ushort) x - (ushort) y);}
static int sub32(int x, int y){ return (int) ((uint) x - (uint) y);}
static long sub64(long x, long y){ return (long) ((ulong) x - (ulong) y);}

static sbyte mul8(sbyte x, sbyte y){ return (sbyte) ((byte) x * (byte) y);}
static short mul16(short x, short y){ return (short) ((ushort) x * (ushort) y);}
static int mul32(int x, int y){ return (int) ((uint) x * (uint) y);}
static long mul64(long x, long y){ return (long) ((ulong) x * (ulong) y);}

static sbyte or8(sbyte x, sbyte y){ return Convert.ToSByte(x | y); }
static short or16(short x, short y){ return Convert.ToInt16(x | y); }
static int or32(int x, int y){ return x | y; }
static long or64(long x, long y){ return x | y;}

static sbyte xor8(sbyte x, sbyte y){ return Convert.ToSByte(x ^ y); }
static short xor16(short x, short y){ return Convert.ToInt16(x ^ y); }
static int xor32(int x, int y){ return x ^ y; }
static long xor64(long x, long y){ return x ^ y;}

static sbyte and8(sbyte x, sbyte y){ return Convert.ToSByte(x & y); }
static short and16(short x, short y){ return Convert.ToInt16(x & y); }
static int and32(int x, int y){ return x & y; }
static long and64(long x, long y){ return x & y;}

static sbyte shl8(sbyte x, sbyte y){ return Convert.ToSByte(x << y); }
static short shl16(short x, short y){ return Convert.ToInt16(x << y); }
static int shl32(int x, int y){ return x << y; }
static long shl64(long x, long y){ return x << Convert.ToInt32(y); }

static sbyte ashr8(sbyte x, sbyte y){ return Convert.ToSByte(x >> y); }
static short ashr16(short x, short y){ return Convert.ToInt16(x >> y); }
static int ashr32(int x, int y){ return x >> y; }
static long ashr64(long x, long y){ return x >> Convert.ToInt32(y); }

static sbyte sdiv8(sbyte x, sbyte y){
    var q = squot8(x,y);
    var r = srem8(x,y);
    return (sbyte) (q - (((r != (sbyte) 0) && ((r < (sbyte) 0) != (y < (sbyte) 0))) ? (sbyte) 1 : (sbyte) 0));
}
static short sdiv16(short x, short y){
    var q = squot16(x,y);
    var r = srem16(x,y);
    return (short) (q - (((r != (short) 0) && ((r < (short) 0) != (y < (short) 0))) ? (short) 1 : (short) 0));
}
static int sdiv32(int x, int y){
    var q = squot32(x,y);
    var r = srem32(x,y);
    return q - (((r != (int) 0) && ((r < (int) 0) != (y < (int) 0))) ? (int) 1 : (int) 0);
}
static long sdiv64(long x, long y){
    var q = squot64(x,y);
    var r = srem64(x,y);
    return q - (((r != (long) 0) && ((r < (long) 0) != (y < (long) 0))) ? (long) 1 : (long) 0);
}

static sbyte smod8(sbyte x, sbyte y){
    var r = srem8(x,y);
    return (sbyte) (r + ((r == (sbyte) 0 || (x > (sbyte) 0 && y > (sbyte) 0) || (x < (sbyte) 0 && y < (sbyte) 0)) ? (sbyte) 0 : y));
}
static short smod16(short x, short y){
    var r = srem16(x,y);
    return (short) (r + ((r == (short) 0 || (x > (short) 0 && y > (short) 0) || (x < (short) 0 && y < (short) 0)) ? (short) 0 : y));
}
static int smod32(int x, int y){
    var r = srem32(x,y);
    return (int) r + ((r == (int) 0 || (x > (int) 0 && y > (int) 0) || (x < (int) 0 && y < (int) 0)) ? (int) 0 : y);
}
static long smod64(long x, long y){
    var r = srem64(x,y);
    return (long) r + ((r == (long) 0 || (x > (long) 0 && y > (long) 0) || (x < (long) 0 && y < (long) 0)) ? (long) 0 : y);
}

static sbyte udiv8(sbyte x, sbyte y){ return signed((byte) (unsigned(x) / unsigned(y))); }
static short udiv16(short x, short y){ return signed((ushort) (unsigned(x) / unsigned(y))); }
static int udiv32(int x, int y){ return signed(unsigned(x) / unsigned(y)); }
static long udiv64(long x, long y){ return signed(unsigned(x) / unsigned(y)); }

static sbyte umod8(sbyte x, sbyte y){ return signed((byte) (unsigned(x) % unsigned(y))); }
static short umod16(short x, short y){ return signed((ushort) (unsigned(x) % unsigned(y))); }
static int umod32(int x, int y){ return signed(unsigned(x) % unsigned(y)); }
static long umod64(long x, long y){ return signed(unsigned(x) % unsigned(y)); }

static sbyte squot8(sbyte x, sbyte y){ return (sbyte) Math.Truncate(ToSingle(x) / ToSingle(y)); }
static short squot16(short x, short y){ return (short) Math.Truncate(ToSingle(x) / ToSingle(y)); }
static int squot32(int x, int y){ return (int) Math.Truncate(ToSingle(x) / ToSingle(y)); }
static long squot64(long x, long y){ return (long) Math.Truncate(ToSingle(x) / ToSingle(y)); }

// static Maybe change srem, it calls np.fmod originally so i dont know
static sbyte srem8(sbyte x, sbyte y){ return (sbyte) ((sbyte) x % (sbyte) y);}
static short srem16(short x, short y){ return (short) ((short) x % (short) y);}
static int srem32(int x, int y){ return (int) ((int) x % (int) y);}
static long srem64(long x, long y){ return (long) ((long) x % (long) y);}

static sbyte smin8(sbyte x, sbyte y){ return Math.Min(x,y);}
static short smin16(short x, short y){ return Math.Min(x,y);}
static int smin32(int x, int y){ return Math.Min(x,y);}
static long smin64(long x, long y){ return Math.Min(x,y);}

static sbyte smax8(sbyte x, sbyte y){ return Math.Max(x,y);}
static short smax16(short x, short y){ return Math.Max(x,y);}
static int smax32(int x, int y){ return Math.Max(x,y);}
static long smax64(long x, long y){ return Math.Max(x,y);}

static sbyte umin8(sbyte x, sbyte y){ return signed(Math.Min(unsigned(x),unsigned(y)));}
static short umin16(short x, short y){ return signed(Math.Min(unsigned(x),unsigned(y)));}
static int umin32(int x, int y){ return signed(Math.Min(unsigned(x),unsigned(y)));}
static long umin64(long x, long y){ return signed(Math.Min(unsigned(x),unsigned(y)));}

static sbyte umax8(sbyte x, sbyte y){ return signed(Math.Max(unsigned(x),unsigned(y)));}
static short umax16(short x, short y){ return signed(Math.Max(unsigned(x),unsigned(y)));}
static int umax32(int x, int y){ return signed(Math.Max(unsigned(x),unsigned(y)));}
static long umax64(long x, long y){ return signed(Math.Max(unsigned(x),unsigned(y)));}

static float fmin32(float x, float y){ return Math.Min(x,y);}
static double fmin64(double x, double y){ return Math.Min(x,y);}
static float fmax32(float x, float y){ return Math.Max(x,y);}
static double fmax64(double x, double y){ return Math.Max(x,y);}

static sbyte pow8(sbyte x, sbyte y){sbyte res = 1;for (var i = 0; i < y; i++){res *= x;}return res;}
static short pow16(short x, short y){short res = 1;for (var i = 0; i < y; i++){res *= x;}return res;}
static int pow32(int x, int y){int res = 1;for (var i = 0; i < y; i++){res *= x;}return res;}
static long pow64(long x, long y){long res = 1;for (var i = 0; i < y; i++){res *= x;}return res;}

static float fpow32(float x, float y){ return Convert.ToSingle(Math.Pow(x,y));}
static double fpow64(double x, double y){ return Convert.ToDouble(Math.Pow(x,y));}

static bool sle8(sbyte x, sbyte y){ return x <= y ;}
static bool sle16(short x, short y){ return x <= y ;}
static bool sle32(int x, int y){ return x <= y ;}
static bool sle64(long x, long y){ return x <= y ;}

static bool slt8(sbyte x, sbyte y){ return x < y ;}
static bool slt16(short x, short y){ return x < y ;}
static bool slt32(int x, int y){ return x < y ;}
static bool slt64(long x, long y){ return x < y ;}

static bool ule8(sbyte x, sbyte y){ return unsigned(x) <= unsigned(y) ;}
static bool ule16(short x, short y){ return unsigned(x) <= unsigned(y) ;}
static bool ule32(int x, int y){ return unsigned(x) <= unsigned(y) ;}
static bool ule64(long x, long y){ return unsigned(x) <= unsigned(y) ;}

static bool ult8(sbyte x, sbyte y){ return unsigned(x) < unsigned(y) ;}
static bool ult16(short x, short y){ return unsigned(x) < unsigned(y) ;}
static bool ult32(int x, int y){ return unsigned(x) < unsigned(y) ;}
static bool ult64(long x, long y){ return unsigned(x) < unsigned(y) ;}

static sbyte lshr8(sbyte x, sbyte y){ return ToSByte((sbyte) ((uint) x) >> ((int) y));}
static short lshr16(short x, short y){ return ToInt16((ushort) x >> (short) y);}
static int lshr32(int x, int y){ return (int) ((uint) (x) >> (int) y);}
static long lshr64(long x, long y){ return (long) ((ulong) x >> (int) y);}

static sbyte sext_i8_i8(sbyte x){return (sbyte) (x);}
static short sext_i8_i16(sbyte x){return (short) (x);}
static int sext_i8_i32(sbyte x){return (int) (x);}
static long sext_i8_i64(sbyte x){return (long) (x);}

static sbyte sext_i16_i8(short x){return (sbyte) (x);}
static short sext_i16_i16(short x){return (short) (x);}
static int sext_i16_i32(short x){return (int) (x);}
static long sext_i16_i64(short x){return (long) (x);}

static sbyte sext_i32_i8(int x){return (sbyte) (x);}
static short sext_i32_i16(int x){return (short) (x);}
static int sext_i32_i32(int x){return (int) (x);}
static long sext_i32_i64(int x){return (long) (x);}

static sbyte sext_i64_i8(long x){return (sbyte) (x);}
static short sext_i64_i16(long x){return (short) (x);}
static int sext_i64_i32(long x){return (int) (x);}
static long sext_i64_i64(long x){return (long) (x);}

static sbyte zext_i8_i8(sbyte x)   {return (sbyte) ((byte)(x));}
static short zext_i8_i16(sbyte x)  {return (short)((byte)(x));}
static int   zext_i8_i32(sbyte x)  {return (int)((byte)(x));}
static long  zext_i8_i64(sbyte x)  {return (long)((byte)(x));}

static sbyte zext_i16_i8(short x)  {return (sbyte) ((ushort)(x));}
static short zext_i16_i16(short x) {return (short)((ushort)(x));}
static int   zext_i16_i32(short x) {return (int)((ushort)(x));}
static long  zext_i16_i64(short x) {return (long)((ushort)(x));}

static sbyte zext_i32_i8(int x){return (sbyte) ((uint)(x));}
static short zext_i32_i16(int x){return (short)((uint)(x));}
static int   zext_i32_i32(int x){return (int)((uint)(x));}
static long  zext_i32_i64(int x){return (long)((uint)(x));}

static sbyte zext_i64_i8(long x){return (sbyte) ((ulong)(x));}
static short zext_i64_i16(long x){return (short)((ulong)(x));}
static int   zext_i64_i32(long x){return (int)((ulong)(x));}
static long  zext_i64_i64(long x){return (long)((ulong)(x));}

static sbyte ssignum(sbyte x){return (sbyte) Math.Sign(x);}
static short ssignum(short x){return (short) Math.Sign(x);}
static int ssignum(int x){return Math.Sign(x);}
static long ssignum(long x){return (long) Math.Sign(x);}

static sbyte usignum(sbyte x){return ((byte) x > 0) ? (sbyte) 1 : (sbyte) 0;}
static short usignum(short x){return ((ushort) x > 0) ? (short) 1 : (short) 0;}
static int usignum(int x){return ((uint) x > 0) ? (int) 1 : (int) 0;}
static long usignum(long x){return ((ulong) x > 0) ? (long) 1 : (long) 0;}

static float sitofp_i8_f32(sbyte x){return Convert.ToSingle(x);}
static float sitofp_i16_f32(short x){return Convert.ToSingle(x);}
static float sitofp_i32_f32(int x){return Convert.ToSingle(x);}
static float sitofp_i64_f32(long x){return Convert.ToSingle(x);}

static double sitofp_i8_f64(sbyte x){return Convert.ToDouble(x);}
static double sitofp_i16_f64(short x){return Convert.ToDouble(x);}
static double sitofp_i32_f64(int x){return Convert.ToDouble(x);}
static double sitofp_i64_f64(long x){return Convert.ToDouble(x);}


static float uitofp_i8_f32(sbyte x){return Convert.ToSingle(unsigned(x));}
static float uitofp_i16_f32(short x){return Convert.ToSingle(unsigned(x));}
static float uitofp_i32_f32(int x){return Convert.ToSingle(unsigned(x));}
static float uitofp_i64_f32(long x){return Convert.ToSingle(unsigned(x));}

static double uitofp_i8_f64(sbyte x){return Convert.ToDouble(unsigned(x));}
static double uitofp_i16_f64(short x){return Convert.ToDouble(unsigned(x));}
static double uitofp_i32_f64(int x){return Convert.ToDouble(unsigned(x));}
static double uitofp_i64_f64(long x){return Convert.ToDouble(unsigned(x));}

static byte fptoui_f32_i8(float x){return Convert.ToByte(Math.Truncate(x));}
static byte fptoui_f64_i8(double x){return Convert.ToByte(Math.Truncate(x));}
static sbyte fptosi_f32_i8(float x){return Convert.ToSByte(Math.Truncate(x));}
static sbyte fptosi_f64_i8(double x){return Convert.ToSByte(Math.Truncate(x));}

static ushort fptoui_f32_i16(float x){return Convert.ToUInt16(Math.Truncate(x));}
static ushort fptoui_f64_i16(double x){return Convert.ToUInt16(Math.Truncate(x));}
static short fptosi_f32_i16(float x){return Convert.ToInt16(Math.Truncate(x));}
static short fptosi_f64_i16(double x){return Convert.ToInt16(Math.Truncate(x));}

static uint fptoui_f32_i32(float x){return Convert.ToUInt32(Math.Truncate(x));}
static uint fptoui_f64_i32(double x){return Convert.ToUInt32(Math.Truncate(x));}
static int fptosi_f32_i32(float x){return Convert.ToInt32(Math.Truncate(x));}
static int fptosi_f64_i32(double x){return Convert.ToInt32(Math.Truncate(x));}

static ulong fptoui_f32_i64(float x){return Convert.ToUInt64(Math.Truncate(x));}
static ulong fptoui_f64_i64(double x){return Convert.ToUInt64(Math.Truncate(x));}
static long fptosi_f32_i64(float x){return Convert.ToInt64(Math.Truncate(x));}
static long fptosi_f64_i64(double x){return Convert.ToInt64(Math.Truncate(x));}

static double fpconv_f32_f64(float x){return Convert.ToDouble(x);}
static float fpconv_f64_f32(double x){return Convert.ToSingle(x);}

static double futhark_log64(double x){return Math.Log(x);}
static double futhark_log2_64(double x){return Math.Log(x,2.0);}
static double futhark_log10_64(double x){return Math.Log10(x);}
static double futhark_sqrt64(double x){return Math.Sqrt(x);}
static double futhark_exp64(double x){return Math.Exp(x);}
static double futhark_cos64(double x){return Math.Cos(x);}
static double futhark_sin64(double x){return Math.Sin(x);}
static double futhark_tan64(double x){return Math.Tan(x);}
static double futhark_acos64(double x){return Math.Acos(x);}
static double futhark_asin64(double x){return Math.Asin(x);}
static double futhark_atan64(double x){return Math.Atan(x);}
static double futhark_atan2_64(double x, double y){return Math.Atan2(x, y);}
static bool futhark_isnan64(double x){return double.IsNaN(x);}
static bool futhark_isinf64(double x){return double.IsInfinity(x);}
static long futhark_to_bits64(double x){return BitConverter.ToInt64(BitConverter.GetBytes(x),0);}
static double futhark_from_bits64(long x){return BitConverter.ToDouble(BitConverter.GetBytes(x),0);}

static float futhark_log32(float x){return (float) Math.Log(x);}
static float futhark_log2_32(float x){return (float) Math.Log(x,2.0);}
static float futhark_log10_32(float x){return (float) Math.Log10(x);}
static float futhark_sqrt32(float x){return (float) Math.Sqrt(x);}
static float futhark_exp32(float x){return (float) Math.Exp(x);}
static float futhark_cos32(float x){return (float) Math.Cos(x);}
static float futhark_sin32(float x){return (float) Math.Sin(x);}
static float futhark_tan32(float x){return (float) Math.Tan(x);}
static float futhark_acos32(float x){return (float) Math.Acos(x);}
static float futhark_asin32(float x){return (float) Math.Asin(x);}
static float futhark_atan32(float x){return (float) Math.Atan(x);}
static float futhark_atan2_32(float x, float y){return (float) Math.Atan2(x, y);}
static bool futhark_isnan32(float x){return float.IsNaN(x);}
static bool futhark_isinf32(float x){return float.IsInfinity(x);}
static int futhark_to_bits32(float x){return BitConverter.ToInt32(BitConverter.GetBytes(x), 0);}
static float futhark_from_bits32(int x){return BitConverter.ToSingle(BitConverter.GetBytes(x), 0);}

static float futhark_round32(float x){return (float) Math.Round(x);}
static double futhark_round64(double x){return Math.Round(x);}

static bool llt (bool x, bool y){return (!x && y);}
static bool lle (bool x, bool y){return (!x || y);}

