/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * mason.cli.build_command
 *
 * Implements the `mason build` subcommand
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module mason.cli.build_command;

public import moss.core.cli;
import moss.core;
import std.stdio;
import mason.build.context;
import mason.build.controller;
import mason.cli : MasonCLI;
import std.parallelism : totalCPUs;
import moss.core.logger;

/**
 * The BuildCommand is responsible for handling requests to build stone.yml
 * formatted files into useful binary packages.
 */
@CommandName("build") @CommandAlias("bi")
@CommandHelp("Build a package",
        "Build a binary package from the given package specification file. It will
be built using the locally available build dependencies and the resulting
binary packages (.stone) will be emitted to the output directory, which
defaults to the current working directory.")
@CommandUsage("[spec]")
public struct BuildCommand
{
    /** Extend BaseCommand with BuildCommand specific functionality */
    BaseCommand pt;
    alias pt this;

    /**
     * Main entry point into the BuildCommand. We expect a list of paths that
     * contain "stone.yml" formatted build description files. For each path
     * we encounter, we initially check the validity and existence.
     *
     * Once all validation is passed, we begin building all of the passed
     * file paths into packages.
     */
    @CommandEntry() int run(ref string[] argv)
    {
        /// FIXME
        ///immutable useDebug = pt.findAncestor!MasonCLI.debugMode;
        ///globalLogLevel = useDebug ? LogLevel.trace : LogLevel.info;
        configureLogger(ColorLoggerFlags.Color | ColorLoggerFlags.Timestamps);
        globalLogLevel = LogLevel.trace;

        import std.exception : enforce;

        auto outputDir = pt.findAncestor!(MasonCLI).outputDirectory;
        auto buildDir = pt.findAncestor!(MasonCLI).buildDir;

        buildContext.outputDirectory = outputDir;
        buildContext.jobs = jobs;

        /* Auto discover job count */
        if (buildContext.jobs < 1)
        {
            buildContext.jobs = totalCPUs - 1;
        }
        buildContext.rootDir = buildDir;

        auto controller = new BuildController(architecture);
        foreach (specURI; argv)
        {
            if (!controller.build(specURI))
            {
                return ExitStatus.Failure;
            }
        }

        return ExitStatus.Success;
    }

    /** Specify the number of build jobs to execute in parallel. */
    @Option("j", "jobs", "Set the number of parallel build jobs (0 = automatic)") int jobs = 0;

    /** Set the architecture to build for. Defaults to native */
    @Option("a", "architecture", "Target architecture for the build") string architecture = "native";
}
