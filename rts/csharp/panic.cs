void panic(int exitcode, string str, params Object[] args)
{
    var prog_name = Environment.GetCommandLineArgs()[0];
    Console.Write(String.Format("{0}:", prog_name));
    Console.Write(String.Format(str, args));
    Environment.Exit(exitcode);
}

void futharkAssert(bool assertion)
{
    if (!assertion)
    {
        Environment.Exit(1);
    }
}

void futharkAssert(bool assertion, string errorMsg)
{
    if (!assertion)
    {
        Console.Error.WriteLine(errorMsg);
        Environment.Exit(1);
    }
}
